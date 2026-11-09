# OpenShift console plugin template

This project is a minimal template for writing a new OpenShift Console dynamic
plugin.

[Openshift console plugins](https://github.com/openshift/console/tree/main/frontend/packages/console-dynamic-plugin-sdk)
allow you to extend the [OpenShift web console](https://github.com/openshift/console)
at runtime, adding custom pages and other extensions. They are based on
[webpack module federation](https://webpack.js.org/concepts/module-federation/).
Plugins are registered with console using the `ConsolePlugin` custom resource
and enabled in the console operator config by a cluster administrator.

The `main` branch of this repository contains an example plugin which works
with the latest version. To see an example of a plugin which works with an older
version, visit the appropriate `release-4.x` branch.

[Node.js](https://nodejs.org/en/) and [yarn](https://yarnpkg.com) are required
to build and run the example. To run OpenShift console in a container, either
[Docker](https://www.docker.com) or [podman 3.2.0+](https://podman.io) and
[oc](https://console.redhat.com/openshift/downloads) are required.

## Getting started

> [!IMPORTANT]
> To use this template, **DO NOT FORK THIS REPOSITORY**! Click **Use this template**, then select
> [**Create a new repository**](https://github.com/new?template_name=console-plugin-template&template_owner=openshift)
> to create a new repository.
>
> ![A screenshot showing where the "Use this template" button is located](https://i.imgur.com/AhaySbU.png)
>
> **Forking this repository** for purposes outside of contributing to this repository
> **will cause issues**, as users cannot have more than one fork of a template repository
> at a time. This could prevent future users from forking and contributing to your plugin.
>
> Your fork would also behave like a template repository, which might be confusing for
> contributiors, because it is not possible for repositories generated from a template
> repository to contribute back to the template.

After cloning your instantiated repository, you must update the plugin metadata, such as the
plugin name in the `consolePlugin` declaration of [package.json](package.json).

```json
"consolePlugin": {
  "name": "console-plugin-template",
  "version": "0.0.1",
  "displayName": "My Plugin",
  "description": "Enjoy this shiny, new console plugin!",
  "exposedModules": {
    "ExamplePage": "./components/ExamplePage"
  },
  "dependencies": {
    "@console/pluginAPI": "*"
  }
}
```

The template adds a single example page in the Home navigation section. The
extension is declared in the [console-extensions.json](console-extensions.json)
file and the React component is declared in
[src/components/ExamplePage.tsx](src/components/ExamplePage.tsx).

You can run the plugin using a local development environment or build an image
to deploy it to a cluster.

## Development

### Option 1: Local

In one terminal window, run:

1. `yarn install`
2. `yarn run start`

In another terminal window, run:

1. `oc login` (requires [oc](https://console.redhat.com/openshift/downloads) and an [OpenShift cluster](https://console.redhat.com/openshift/create))
2. `yarn run start-console` (requires [Docker](https://www.docker.com) or [podman 3.2.0+](https://podman.io))

This will run the OpenShift console in a container connected to the cluster
you've logged into. The plugin HTTP server runs on port 9001 with CORS enabled.
Navigate to <http://localhost:9000/example> to see the running plugin.

#### Running start-console with Apple silicon and podman

If you are using podman on a Mac with Apple silicon, `yarn run start-console`
might fail since it runs an amd64 image. You can workaround the problem with
[qemu-user-static](https://github.com/multiarch/qemu-user-static) by running
these commands:

```bash
podman machine ssh
sudo -i
rpm-ostree install qemu-user-static
systemctl reboot
```

### Option 2: Docker + VSCode Remote Container

Make sure the
[Remote Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
extension is installed. This method uses Docker Compose where one container is
the OpenShift console and the second container is the plugin. It requires that
you have access to an existing OpenShift cluster. After the initial build, the
cached containers will help you start developing in seconds.

1. Create a `dev.env` file inside the `.devcontainer` folder with the correct values for your cluster:

```bash
OC_PLUGIN_NAME=console-plugin-template
OC_URL=https://api.example.com:6443
OC_USER=kubeadmin
OC_PASS=<password>
```

2. `(Ctrl+Shift+P) => Remote Containers: Open Folder in Container...`
3. `yarn run start`
4. Navigate to <http://localhost:9000/example>

## Docker image

Before you can deploy your plugin on a cluster, you must build an image and
push it to an image registry.

1. Build the image:

   ```sh
   docker build -t quay.io/my-repository/my-plugin:latest .
   ```

2. Run the image:

   ```sh
   docker run -it --rm -d -p 9001:80 quay.io/my-repository/my-plugin:latest
   ```

3. Push the image:

   ```sh
   docker push quay.io/my-repository/my-plugin:latest
   ```

NOTE: If you have a Mac with Apple silicon, you will need to add the flag
`--platform=linux/amd64` when building the image to target the correct platform
to run in-cluster.

## Deployment on cluster

A [Helm](https://helm.sh) chart is available to deploy the plugin to an OpenShift environment.

The following Helm parameters are required:

`plugin.image`: The location of the image containing the plugin that was previously pushed

Additional parameters can be specified if desired. Consult the chart [values](charts/openshift-console-plugin/values.yaml) file for the full set of supported parameters.

### Installing the Helm Chart

Install the chart using the name of the plugin as the Helm release name into a new namespace or an existing namespace as specified by the `plugin_console-plugin-template` parameter and providing the location of the image within the `plugin.image` parameter by using the following command:

```shell
helm upgrade -i  my-plugin charts/openshift-console-plugin -n my-namespace --create-namespace --set plugin.image=my-plugin-image-location
```

NOTE: When deploying on OpenShift 4.10, it is recommended to add the parameter `--set plugin.securityContext.enabled=false` which will omit configurations related to Pod Security.

NOTE: When defining i18n namespace, adhere `plugin__<name-of-the-plugin>` format. The name of the plugin should be extracted from the `consolePlugin` declaration within the [package.json](package.json) file.

### Serving certificate rotation

The chart mounts the serving certificate secret at `/var/cert` and the nginx
configuration ConfigMap at `/etc/nginx/plugin`, and passes
`-c /etc/nginx/plugin/nginx.conf` as container arguments, which the container
engine appends to the image entrypoint `nginx -g "daemon off;"`. The arguments
assume that the image's entrypoint is nginx, as in the [Dockerfile](Dockerfile).
With `-c`, nginx resolves relative `include` paths against `/etc/nginx/plugin`,
so a customized configuration has to use absolute paths such as
`/etc/nginx/mime.types`. Neither volume uses a `subPath` mount, because
Kubernetes never updates files mounted with `subPath`.

nginx serves a rotated certificate without a reload or restart. The
`ssl_certificate` and `ssl_certificate_key` paths in the nginx configuration
contain the variable `$plugin_certificate_dir`, so nginx reads the certificate
and key from the mounted secret on every full TLS handshake instead of once at
startup. When the kubelet updates the secret volume, for example after the
service CA operator rotates the serving certificate, new connections get the
new certificate. Connections that are already open keep the certificate they
started with, and a client that resumes an earlier TLS session does not
receive a certificate. The kubelet can take a minute or more to deliver an
updated secret to a running pod.

`$plugin_certificate_dir` comes from a `map` with a constant source and only a
default value, so it is always `/var/cert`. Nothing the client sends, such as
the TLS server name, is used in the path: clients that send no server name, an
unexpected name, or a name that looks like a path all get the certificate from
`/var/cert`.

Loading the certificate on every handshake has a cost:

- nginx reads and parses both files for every full TLS handshake. The
  [nginx documentation](https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_certificate)
  notes that this may have a negative impact on performance. nginx 1.27.4 added
  `ssl_certificate_cache` to cache such certificates, but the nginx 1.20 in the
  `ubi9/nginx-120` image does not support it, so the configuration does not use
  it.
- nginx does not check the certificate at startup, and `nginx -t` does not
  either. If the files are missing or malformed, or the key does not match the
  certificate, nginx keeps running but fails every full handshake with a TLS
  `internal_error` alert and logs an error such as
  `cannot load certificate "/var/cert/tls.crt"` or `key values mismatch` for
  each one. nginx keeps no copy of a previous certificate to fall back to, so
  an invalid secret affects the running pods at once, and all replicas fail
  together because they mount the same secret. The chart defines no readiness
  probe, so the pods stay ready while this happens. As soon as the secret
  contains a valid certificate and key again, the next handshake uses them,
  without a restart.
- The certificate and the key are separate files that nginx reads one after
  the other, so a handshake that coincides with a secret update can read them
  from different versions. nginx rejects such a pair with a
  `key values mismatch` error, fails that handshake and keeps running; the
  client's next connection gets the new pair.

nginx reads its configuration only at startup, so changes to the nginx
configuration, including the TLS settings below, take effect when pods are
replaced. The chart adds a checksum of the configuration to the pod template,
so `helm upgrade` with changed values rolls out new pods. Anything that edits
the ConfigMap directly has to roll out the deployment itself.

Run `./test-nginx.sh` to test the chart's nginx settings and the runtime
behavior in the nginx image. It needs podman or docker, and helm
(`./install_helm.sh` installs helm to `/tmp/helm`). It runs nginx as an
arbitrary non-root UID with the chart's container arguments and rotates the
certificate the way the kubelet updates a secret volume, which emulates but
does not replace testing with a real kubelet and the service CA operator. Set
`TEST_IMAGE` to test an image built from the [Dockerfile](Dockerfile).

### TLS security profile

The chart sets the nginx TLS protocols and ciphers explicitly from
`plugin.tls`, whose fields mirror the `TLSProfileSpec` of the OpenShift
[`config.openshift.io/v1` TLS security profile](https://github.com/openshift/api/blob/master/config/v1/types_tlssecurityprofile.go).
The defaults are the protocol versions and ciphers of the OpenShift
**Intermediate** profile: TLS 1.2 or later, with the profile's TLS 1.2 ciphers
and TLS 1.3 cipher suites. Intermediate is the platform default when the
cluster `APIServer` resource does not set `spec.tlsSecurityProfile`. The API
notes that this default can change in later releases. `groups` is empty by
default, so the key exchange groups come from the image's system crypto policy
rather than from the profile's group list; set `groups` to apply a list.

The values are rendered as follows:

| Value | nginx directive |
| --- | --- |
| `minTLSVersion: VersionTLS12` | `ssl_protocols TLSv1.2 TLSv1.3;` |
| `minTLSVersion: VersionTLS13` | `ssl_protocols TLSv1.3;` |
| `ciphers` entries without a `TLS_` prefix (TLS 1.2) | `ssl_ciphers`, required for `VersionTLS12` |
| `ciphers` entries with a `TLS_` prefix (TLS 1.3) | `ssl_conf_command Ciphersuites`; without them the TLS 1.3 suites come from the image's system crypto policy |
| `groups` (optional) | `ssl_ecdh_curve`; empty uses the image's system crypto policy |

`VersionTLS10` and `VersionTLS11`, used by the Old profile, are rejected
because the system crypto policy of the RHEL 9 based nginx image does not allow
TLS versions below 1.2.

For example, to use the Modern profile:

```shell
helm upgrade -i my-plugin charts/openshift-console-plugin -n my-namespace --set plugin.image=my-plugin-image-location \
  --set plugin.tls.minTLSVersion=VersionTLS13 \
  --set-json 'plugin.tls.ciphers=["TLS_AES_128_GCM_SHA256","TLS_AES_256_GCM_SHA384","TLS_CHACHA20_POLY1305_SHA256"]'
```

The chart and the image do not read any cluster configuration. The plugin
serves the configured values regardless of the cluster's TLS security profile,
so fixed defaults alone do not make it follow cluster TLS policy.

#### Following the cluster TLS profile from an operator

An operator that deploys a plugin built from this template and has to follow
the cluster TLS configuration is responsible for resolving it, rendering the
nginx settings and confirming the result:

1. Watch the `apiservers.config.openshift.io` resource named `cluster`.
2. Decide from `spec.tlsAdherence` whether the plugin has to honor the cluster
   profile, using `ShouldHonorClusterTLSProfile` from the library-go
   [`pkg/crypto`](https://github.com/openshift/library-go/blob/master/pkg/crypto/tls_adherence.go)
   package. When the field is unset or `LegacyAdheringComponentsOnly`,
   components that did not previously follow the cluster profile may keep their
   own TLS configuration. With `StrictAllComponents`, or a value the operator
   does not recognize, the plugin must use the cluster profile unless an
   explicit component-specific TLS configuration overrides it.
3. Resolve `spec.tlsSecurityProfile` to a `TLSProfileSpec`: `custom` for the
   `Custom` type, otherwise the `TLSProfiles` entry for the type from the
   openshift/api version that matches the cluster release, with Intermediate
   when the field is unset.
4. Map the resolved spec to `plugin.tls`, dropping entries that this nginx and
   OpenSSL build does not support. On FIPS clusters, keep only FIPS-approved
   groups: library-go's `GetSecurityProfileGroups` keeps only `secp256r1`,
   `secp384r1` and `secp521r1` when the operator runs in FIPS mode.
   A profile that requires TLS 1.0 or 1.1 cannot be served by this image, so
   report it in the operator's status instead of applying a different profile
   silently.
5. Update the nginx configuration ConfigMap, either through the chart values
   or by rendering the equivalent `ssl_*` directives from the table above, and
   roll out the deployment so that new pods load it: nginx does not reload its
   configuration. With the chart, `helm upgrade` rolls out pods when the
   rendered configuration changes.
6. Confirm the change once the rollout has finished, for example by making a
   TLS handshake against the plugin service, and report failures in the
   operator's status. Apply the same steps whenever the `APIServer` resource
   changes.

## i18n

The plugin template demonstrates how you can translate messages in with [react-i18next](https://react.i18next.com/). The i18n namespace must match
the name of the `ConsolePlugin` resource with the `plugin__` prefix to avoid
naming conflicts. For example, the plugin template uses the
`plugin__console-plugin-template` namespace. You can use the `useTranslation` hook
with this namespace as follows:

```tsx
const Header: React.FC = () => {
  const { t } = useTranslation('plugin__console-plugin-template');
  return <h1>{t('Hello, World!')}</h1>;
};
```

For labels in `console-extensions.json`, you can use the format
`%plugin__console-plugin-template~My Label%`. Console will replace the value with
the message for the current language from the `plugin__console-plugin-template`
namespace. For example:

```json
  {
    "type": "console.navigation/section",
    "properties": {
      "id": "admin-demo-section",
      "perspective": "admin",
      "name": "%plugin__console-plugin-template~Plugin Template%"
    }
  }
```

Running `yarn i18n` updates the JSON files in the `locales` folder of the
plugin template when adding or changing messages.

## Linting

This project adds oxfmt, oxlint, and stylelint. Linting can be run with
`yarn run lint`.

Linting uses [oxlint](https://oxc.rs/docs/guide/usage/linter.html) (configured
in `.oxlintrc.json`) with type-aware rules enabled via
[tsgolint](https://github.com/oxc-project/tsgolint), and formatting uses
[oxfmt](https://oxc.rs/docs/guide/usage/formatter.html) (configured in
`.oxfmtrc.json`). The `eslint-plugin-playwright` and
`eslint-plugin-testing-library` packages are still installed because oxlint
loads them as JS plugins for their e2e and unit test rules; the `eslint`
package itself remains installed only as their peer dependency — ESLint is
not invoked and has no configuration.

The stylelint config disallows defining colors since these cause problems with dark
mode. Use [PatternFly semantic tokens](https://www.patternfly.org/tokens/all-patternfly-tokens)
for colors instead.

The stylelint config also disallows naked element selectors like `table` and
`.pf-` or `.co-` prefixed classes. This prevents plugins from accidentally
overwriting default console styles, breaking the layout of existing pages.
Note that CSS Modules only scope class names, not element selectors, so these
rules stay necessary even in `*.module.css` files. Use CSS Modules
(`*.module.css`) for custom styles; class names are scoped automatically and
linted for kebab-case. Please don't disable these rules without understanding
how they can break console styles!

## References

- [Console Plugin SDK README](https://github.com/openshift/console/tree/main/frontend/packages/console-dynamic-plugin-sdk)
- [Customization Plugin Example](https://github.com/spadgett/console-customization-plugin)
- [Dynamic Plugin Enhancement Proposal](https://github.com/openshift/enhancements/blob/master/enhancements/console/dynamic-plugins.md)
