#!/usr/bin/env bash
#
# Tests the nginx runtime: the Helm chart's nginx settings, and nginx running in
# the nginx image the way the chart runs it, as an arbitrary non-root UID, while
# the serving certificate is rotated the way the kubelet updates a Secret
# volume.
#
# Requires podman or docker, and helm (./install_helm.sh installs it to
# /tmp/helm).
#
# TEST_UID    UID to run nginx as (default: 54321).
# TEST_IMAGE  Image to test. By default the runtime base image from the
#             Dockerfile is run with the Dockerfile's entrypoint and a test
#             plugin-manifest.json in place of the built plugin. Set it to an
#             image built from the Dockerfile to test that image.

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CHART_DIR="$SCRIPT_DIR/charts/openshift-console-plugin"
CONF_DIR=/etc/nginx/plugin
CERT_DIR=/var/cert
# Arbitrary UID without a passwd entry and with GID 0, like the UIDs that
# OpenShift assigns. It must be mappable by the container engine.
TEST_UID=${TEST_UID:-54321}

# The log checks read container logs, so podman must not use a log driver
# such as journald that may be unavailable.
LOG_ARGS=()
if [ -x "$(command -v podman)" ]; then
  ENGINE=podman
  LOG_ARGS=(--log-driver k8s-file)
elif [ -x "$(command -v docker)" ]; then
  ENGINE=docker
else
  echo "podman or docker is required" >&2
  exit 1
fi

HELM=${HELM:-$(command -v helm || echo /tmp/helm)}
if [ ! -x "$HELM" ]; then
  echo "helm is required; run ./install_helm.sh or set HELM" >&2
  exit 1
fi

WORK=$(mktemp -d)
CONTAINERS=()
cleanup() {
  for container in ${CONTAINERS[@]+"${CONTAINERS[@]}"}; do
    "$ENGINE" rm -f "$container" >/dev/null 2>&1 || true
  done
  rm -rf "$WORK"
}
trap cleanup EXIT

if [ -n "${TEST_IMAGE:-}" ]; then
  IMAGE=$TEST_IMAGE
  # The image's own entrypoint and plugin files.
  IMAGE_ARGS=()
  ENTRYPOINT_ARGS=()
else
  IMAGE=$(awk '$1 == "FROM" { image = $2 } END { print image }' "$SCRIPT_DIR/Dockerfile")
  # The base image has a different entrypoint: use the Dockerfile's, which is
  # checked below, and stand in for the plugin files the Dockerfile copies.
  mkdir "$WORK/html"
  echo '{"name": "test-plugin"}' >"$WORK/html/plugin-manifest.json"
  chmod -R a+rX "$WORK/html"
  IMAGE_ARGS=(-v "$WORK/html:/usr/share/nginx/html:ro,z" --entrypoint nginx)
  ENTRYPOINT_ARGS=(-g "daemon off;")
fi

failures=0
pass() { echo "PASS: $*"; }
fail() {
  echo "FAIL: $*"
  failures=$((failures + 1))
}

# check DESCRIPTION COMMAND...: passes when COMMAND succeeds.
check() {
  local description=$1
  shift
  if "$@"; then
    pass "$description"
  else
    fail "$description"
  fi
}

render() {
  "$HELM" template test "$CHART_DIR" --set plugin.image=test "$@"
}

# Prints the nginx.conf entry of the rendered ConfigMap.
render_nginx_conf() {
  render --show-only templates/configmap.yaml "$@" |
    awk '/^  nginx\.conf: \|/ { found = 1; next }
      found && /^    / { print substr($0, 5); next }
      found && /^$/ { print ""; next }
      found { exit }'
}

# Prints the nginx configuration checksum annotation of the rendered pod template.
render_conf_checksum() {
  render --show-only templates/deployment.yaml "$@" | awk '$1 == "checksum/nginx-conf:" { print $2 }'
}

# expect_render_failure DESCRIPTION MESSAGE HELM_ARGS...
expect_render_failure() {
  local description=$1 message=$2 output
  shift 2
  if output=$(render "$@" 2>&1); then
    fail "$description: rendering succeeded"
  elif grep -qF -- "$message" <<<"$output"; then
    pass "$description"
  else
    fail "$description: unexpected error: $output"
  fi
}

echo "== Dockerfile and Helm chart"
# Helpers capture output before grep -q, which can stop reading early and
# would otherwise make the writer's SIGPIPE fail the pipeline under pipefail.
check "Dockerfile runs nginx in the foreground as the entrypoint" \
  grep -qxF 'ENTRYPOINT ["nginx", "-g", "daemon off;"]' "$SCRIPT_DIR/Dockerfile"

render --show-only templates/deployment.yaml >"$WORK/deployment.yaml"
# The container arguments, which the container engine appends to the
# image entrypoint.
CHART_ARGS=()
while IFS= read -r arg; do
  CHART_ARGS+=("$arg")
done < <(awk '/^ *args:$/ { found = 1; next }
  found && /^ *- / { sub(/^ *- /, ""); print; next }
  found { exit }' "$WORK/deployment.yaml")
no_subpath() { ! grep -q 'subPath' "$WORK/deployment.yaml"; }
no_command_or_env() { ! grep -qE '^ *(command|env):' "$WORK/deployment.yaml"; }
mounted_read_only() {
  local mount
  mount=$(grep -B2 "mountPath: $1\$" "$WORK/deployment.yaml")
  grep -q 'readOnly: true' <<<"$mount"
}
check "deployment has no subPath mounts" no_subpath
check "nginx configuration directory is mounted read-only at $CONF_DIR" mounted_read_only "$CONF_DIR"
check "serving certificate directory is mounted read-only at $CERT_DIR" mounted_read_only "$CERT_DIR"
check "container arguments are -c $CONF_DIR/nginx.conf (were: ${CHART_ARGS[*]-none})" \
  test "${CHART_ARGS[*]-}" = "-c $CONF_DIR/nginx.conf"
check "container keeps the image entrypoint and sets no environment" no_command_or_env

default_checksum=$(render_conf_checksum)
check "pod template has an nginx configuration checksum" test -n "$default_checksum"
check "the checksum is stable for unchanged values" test "$(render_conf_checksum)" = "$default_checksum"
modern_checksum=$(render_conf_checksum --set plugin.tls.minTLSVersion=VersionTLS13)
check "changed TLS values change the checksum, so pods roll out" test "$modern_checksum" != "$default_checksum"

render_nginx_conf >"$WORK/intermediate.conf"
render_nginx_conf --set plugin.tls.minTLSVersion=VersionTLS13 \
  --set-json 'plugin.tls.ciphers=["TLS_AES_128_GCM_SHA256","TLS_AES_256_GCM_SHA384","TLS_CHACHA20_POLY1305_SHA256"]' \
  >"$WORK/modern.conf"
render_nginx_conf --set-json 'plugin.tls.groups=["X25519MLKEM768","X25519","secp256r1","secp384r1"]' \
  >"$WORK/groups.conf"
# The configuration without the explicit TLS settings, used as a control to
# show which restrictions come from the rendered TLS settings.
grep -v -E '^ *(ssl_protocols|ssl_ciphers|ssl_conf_command|ssl_ecdh_curve) ' "$WORK/intermediate.conf" \
  >"$WORK/control.conf"

certificate_dir_map() {
  local map
  map=$(awk '/^ *map "" \$plugin_certificate_dir \{$/ { found = 1; next }
    found && /^ *}$/ { exit }
    found { gsub(/^ +| +$/, ""); print }' "$WORK/intermediate.conf")
  [ "$map" = "default $CERT_DIR;" ]
}
# The single quotes below keep nginx variable names literal.
# shellcheck disable=SC2016
only_certificate_dir_variable() {
  local paths
  paths=$(grep -E '^ *ssl_certificate(_key)? ' "$WORK/intermediate.conf")
  [ "$(grep -o '\$[a-z_]*' <<<"$paths" | sort -u)" = '$plugin_certificate_dir' ]
}
no_certificate_cache() { ! grep -q 'ssl_certificate_cache' "$WORK/intermediate.conf"; }
check "certificate directory variable maps a constant to $CERT_DIR only" certificate_dir_map
# shellcheck disable=SC2016
check "certificate path is \$plugin_certificate_dir/tls.crt" \
  grep -qx ' *ssl_certificate *\$plugin_certificate_dir/tls.crt;' "$WORK/intermediate.conf"
# shellcheck disable=SC2016
check "key path is \$plugin_certificate_dir/tls.key" \
  grep -qx ' *ssl_certificate_key *\$plugin_certificate_dir/tls.key;' "$WORK/intermediate.conf"
check "certificate paths use no other variable, such as the client's server name" only_certificate_dir_variable
check "no ssl_certificate_cache, which the image's nginx does not support" no_certificate_cache

no_tls12_ciphers() { ! grep -q 'ssl_ciphers' "$WORK/modern.conf"; }
check "default values render TLS 1.2 and TLS 1.3" grep -qx ' *ssl_protocols *TLSv1.2 TLSv1.3;' "$WORK/intermediate.conf"
check "default values render the Intermediate TLS 1.2 ciphers" grep -qx ' *ssl_ciphers *ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305;' "$WORK/intermediate.conf"
check "default values render the TLS 1.3 cipher suites" grep -qx ' *ssl_conf_command *Ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256;' "$WORK/intermediate.conf"
check "VersionTLS13 renders TLS 1.3 only" grep -qx ' *ssl_protocols *TLSv1.3;' "$WORK/modern.conf"
check "VersionTLS13 renders no TLS 1.2 ciphers" no_tls12_ciphers
check "groups render ssl_ecdh_curve" grep -qx ' *ssl_ecdh_curve *X25519MLKEM768:X25519:secp256r1:secp384r1;' "$WORK/groups.conf"
expect_render_failure "VersionTLS10 is rejected" "is not supported" --set plugin.tls.minTLSVersion=VersionTLS10
expect_render_failure "an unknown version is rejected" "is not supported" --set plugin.tls.minTLSVersion=TLS12
expect_render_failure "VersionTLS12 without TLS 1.2 ciphers is rejected" "at least one TLS 1.2 cipher" \
  --set-json 'plugin.tls.ciphers=["TLS_AES_128_GCM_SHA256"]'
expect_render_failure "a cipher entry with configuration syntax is rejected" "not a valid cipher name" \
  --set-json 'plugin.tls.ciphers=["ECDHE-RSA-AES128-GCM-SHA256; root /"]'
expect_render_failure "a group entry with configuration syntax is rejected" "not a valid group name" \
  --set-json 'plugin.tls.groups=["X25519; root /"]'

# project_conf NAME: lays out the rendered NAME.conf as nginx.conf in a
# directory the way the kubelet lays out a ConfigMap volume.
project_conf() {
  local dir=$WORK/conf-$1 version
  version="..$(date +%Y_%m_%d_%H_%M_%S).1"
  mkdir -p "$dir/$version"
  cp "$WORK/$1.conf" "$dir/$version/nginx.conf"
  ln -s "$version" "$dir/..data"
  ln -s ..data/nginx.conf "$dir/nginx.conf"
  chmod -R a+rX "$dir"
}

# start_nginx NAME: runs the image with the chart's container arguments and
# the rendered NAME.conf, as uid $TEST_UID. $CERT_DIR is an empty tmpfs owned
# by root that the runtime tests write to as root.
start_nginx() {
  project_conf "$1"
  container=$("$ENGINE" run -d ${LOG_ARGS[@]+"${LOG_ARGS[@]}"} --user "$TEST_UID:0" \
    --tmpfs "$CERT_DIR:rw,mode=0755" -v "$WORK/conf-$1:$CONF_DIR:ro,z" \
    -v "$SCRIPT_DIR/nginx/test:/tests:ro,z" ${IMAGE_ARGS[@]+"${IMAGE_ARGS[@]}"} \
    "$IMAGE" ${ENTRYPOINT_ARGS[@]+"${ENTRYPOINT_ARGS[@]}"} "${CHART_ARGS[@]}")
  CONTAINERS+=("$container")
}

# runtime_tests ARGS...: runs nginx/test/runtime-tests.sh ARGS in the container.
runtime_tests() {
  if ! "$ENGINE" exec --user 0 "$container" bash /tests/runtime-tests.sh "$@"; then
    fail "runtime checks ($*) failed; nginx log:"
    "$ENGINE" logs --tail 20 "$container" 2>&1 | sed 's/^/    /'
  fi
}

echo
echo "== Certificate rotation in $IMAGE as uid $TEST_UID"
start_nginx intermediate
runtime_tests rotation "$TEST_UID"
runtime_tests profile intermediate

logs=$("$ENGINE" logs "$container" 2>&1)
log_has() { grep -qF -- "$1" <<<"$logs"; }
# Every certificate or key load error names one of the two fixed files.
load_errors_name_fixed_files() {
  local errors
  errors=$(grep -E 'cannot load certificate|SSL_use_PrivateKey' <<<"$logs" || true)
  [ -n "$errors" ] &&
    ! grep -vE "(cannot load certificate( key)? \"|SSL_use_PrivateKey\(\")$CERT_DIR/tls\.(crt|key)\"" \
      <<<"$errors" >/dev/null
}
no_key_material_logged() { ! grep -qE 'BEGIN [A-Z ]*PRIVATE KEY' <<<"$logs"; }
no_process_crashed() { ! grep -qF 'exited on signal' <<<"$logs"; }
check "nginx logs the missing certificate" \
  log_has "cannot load certificate \"$CERT_DIR/tls.crt\": BIO_new_file() failed"
mismatch_logged() {
  grep -F "SSL_use_PrivateKey(\"$CERT_DIR/tls.key\") failed" <<<"$logs" | grep -qF 'key values mismatch'
}
check "nginx logs the mismatched key" mismatch_logged
check "nginx logs the missing key" \
  log_has "cannot load certificate key \"$CERT_DIR/tls.key\": BIO_new_file() failed"
check "nginx logs the malformed key" \
  log_has "cannot load certificate key \"$CERT_DIR/tls.key\": PEM_read_bio_PrivateKey() failed"
check "nginx logs the malformed certificate" \
  log_has "cannot load certificate \"$CERT_DIR/tls.crt\": PEM_read_bio_X509_AUX() failed"
check "certificate load errors only name $CERT_DIR/tls.crt and $CERT_DIR/tls.key" load_errors_name_fixed_files
check "no private key material in the log" no_key_material_logged
check "no nginx process exited on a signal during the updates" no_process_crashed

started=$SECONDS
"$ENGINE" kill --signal TERM "$container" >/dev/null 2>&1 || true
"$ENGINE" wait "$container" >/dev/null 2>&1 || true
exit_code=$("$ENGINE" inspect -f '{{.State.ExitCode}}' "$container" 2>/dev/null || echo unknown)
check "SIGTERM stops nginx with exit code 0 (was $exit_code)" test "$exit_code" = 0
check "SIGTERM stops nginx promptly ($((SECONDS - started))s)" test $((SECONDS - started)) -lt 10

for profile in modern groups control; do
  echo
  echo "== $profile TLS settings"
  start_nginx "$profile"
  runtime_tests profile "$profile"
  "$ENGINE" rm -f "$container" >/dev/null
done

echo
if ((failures > 0)); then
  echo "$failures check(s) failed"
  exit 1
fi
echo "All nginx checks passed"
