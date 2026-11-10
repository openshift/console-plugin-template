{{/*
Expand the name of the chart.
*/}}
{{- define "openshift-console-plugin.name" -}}
{{- default (default .Chart.Name .Release.Name) .Values.plugin.name | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "openshift-console-plugin.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "openshift-console-plugin.labels" -}}
helm.sh/chart: {{ include "openshift-console-plugin.chart" . }}
{{ include "openshift-console-plugin.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "openshift-console-plugin.selectorLabels" -}}
app: {{ include "openshift-console-plugin.name" . }}
app.kubernetes.io/name: {{ include "openshift-console-plugin.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: {{ include "openshift-console-plugin.name" . }}
{{- end }}

{{/*
Create the name secret containing the certificate
*/}}
{{- define "openshift-console-plugin.certificateSecret" -}}
{{ default (printf "%s-cert" (include "openshift-console-plugin.name" .)) .Values.plugin.certificateSecretName }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "openshift-console-plugin.serviceAccountName" -}}
{{- if .Values.plugin.serviceAccount.create }}
{{- default (include "openshift-console-plugin.name" .) .Values.plugin.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.plugin.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the patcher
*/}}
{{- define "openshift-console-plugin.patcherName" -}}
{{- printf "%s-patcher" (include "openshift-console-plugin.name" .) }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "openshift-console-plugin.patcherServiceAccountName" -}}
{{- if .Values.plugin.patcherServiceAccount.create }}
{{- default (printf "%s-patcher" (include "openshift-console-plugin.name" .)) .Values.plugin.patcherServiceAccount.name }}
{{- else }}
{{- default "default" .Values.plugin.patcherServiceAccount.name }}
{{- end }}
{{- end }}

{{/*
Directory where the serving certificate secret is mounted
*/}}
{{- define "openshift-console-plugin.certificateDir" -}}
/var/cert
{{- end }}

{{/*
Directory where the nginx configuration ConfigMap is mounted. It is a
dedicated directory, not a subPath mount over /etc/nginx/nginx.conf, because
subPath mounts never receive ConfigMap updates.
*/}}
{{- define "openshift-console-plugin.nginxConfigDir" -}}
/etc/nginx/plugin
{{- end }}

{{/*
Path of the nginx configuration file
*/}}
{{- define "openshift-console-plugin.nginxConfigFile" -}}
{{ include "openshift-console-plugin.nginxConfigDir" . }}/nginx.conf
{{- end }}

{{/*
nginx TLS directives rendered from .Values.plugin.tls, which mirrors the
config.openshift.io/v1 TLSProfileSpec fields minTLSVersion, ciphers and groups.
TLS 1.3 cipher suites (TLS_* names) are applied with ssl_conf_command
Ciphersuites, the other ciphers with ssl_ciphers, which only affects TLS 1.2.
*/}}
{{- define "openshift-console-plugin.nginxTLSSettings" -}}
{{- $tls := .Values.plugin.tls | default dict -}}
{{- $minVersion := toString ($tls.minTLSVersion | default "") -}}
{{- $protocols := dict "VersionTLS12" "TLSv1.2 TLSv1.3" "VersionTLS13" "TLSv1.3" -}}
{{- if not (hasKey $protocols $minVersion) -}}
{{- fail (printf "plugin.tls.minTLSVersion %q is not supported: use VersionTLS12 or VersionTLS13 (the nginx image's system crypto policy does not allow TLS 1.0 or 1.1)" $minVersion) -}}
{{- end -}}
{{- $tls12Ciphers := list -}}
{{- $tls13Ciphers := list -}}
{{- range ($tls.ciphers | default list) -}}
{{- if not (regexMatch "^[A-Za-z0-9_-]+$" (toString .)) -}}
{{- fail (printf "plugin.tls.ciphers entry %q is not a valid cipher name" (toString .)) -}}
{{- end -}}
{{- if hasPrefix "TLS_" (toString .) -}}
{{- $tls13Ciphers = append $tls13Ciphers . -}}
{{- else -}}
{{- $tls12Ciphers = append $tls12Ciphers . -}}
{{- end -}}
{{- end -}}
{{- range ($tls.groups | default list) -}}
{{- if not (regexMatch "^[A-Za-z0-9_-]+$" (toString .)) -}}
{{- fail (printf "plugin.tls.groups entry %q is not a valid group name" (toString .)) -}}
{{- end -}}
{{- end -}}
ssl_protocols       {{ get $protocols $minVersion }};
{{- if eq $minVersion "VersionTLS12" }}
{{- if not $tls12Ciphers }}
{{- fail "plugin.tls.ciphers must include at least one TLS 1.2 cipher when plugin.tls.minTLSVersion is VersionTLS12" }}
{{- end }}
ssl_ciphers         {{ join ":" $tls12Ciphers }};
{{- end }}
{{- if $tls13Ciphers }}
ssl_conf_command    Ciphersuites {{ join ":" $tls13Ciphers }};
{{- end }}
{{- with $tls.groups }}
ssl_ecdh_curve      {{ join ":" . }};
{{- end }}
{{- end }}
