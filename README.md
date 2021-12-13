# OpenShift Console Plugin Template

This project is a minimal template for writing a new OpenShift Console dynamic
plugin. It requires OpenShift 4.10.

[Node.js](https://nodejs.org/en/) and [yarn](https://yarnpkg.com) are required
to build and run the example. When installed, run these commands:

## Update the plugin metadata

After cloning this repo, you should update the plugin metadata such as the
plugin name. The metadata is defined in the `consolePlugin` stanza of
package.json. Additionally, update references to `console-plugin-template` and
the plugin image in manifest.yaml. Your plugin must have a unique name.

## Local development

1. `yarn install`
2. `yarn run start`

The server runs on port 9001 with CORS enabled.

See the plugin development section in
[Console Dynamic Plugins README](https://github.com/openshift/console/tree/master/frontend/packages/console-dynamic-plugin-sdk/README.md)
for details on how to run OpenShift console using local plugins.

When a local console server is running, visit <http://localhost:9000/example>
to see the example plugin page.

## Deployment on cluster

You can deploy the plugin to a cluster by applying `manifest.yaml`.

```sh
oc apply -f manifest.yaml
```

Once deployed, patch the
[Console operator](https://github.com/openshift/console-operator)
config to enable the plugin.

```sh
oc patch consoles.operator.openshift.io cluster --patch '{ "spec": { "plugins": ["$PLUGIN_NAME"] } }' --type=merge
```

## Docker image

1. Build the image:
   ```sh
   docker build -t quay.io/$USER/$PLUGIN_NAME:latest .
   ```
2. Run the image:
   ```sh
   docker run -it --rm -d -p 9001:80 quay.io/$USER/$PLUGIN_NAME:latest
   ```
3. Push the image to image registry:
   ```sh
   docker push quay.io/$USER/$PLUGIN_NAME:latest
   ```

## References

* [Console Plugin SDK README](https://github.com/openshift/console/tree/master/frontend/packages/console-dynamic-plugin-sdk)
* [Customization Plugin Example](https://github.com/spadgett/console-customization-plugin)
