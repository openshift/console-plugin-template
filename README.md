# OpenShift Console Plugin Template

This project is a minimal template for writing a new OpenShift Console dynamic
plugin. It requires OpenShift 4.10.

[Node.js](https://nodejs.org/en/) and [yarn](https://yarnpkg.com) are required
to build and run the example.

## Update the plugin metadata

After cloning this repo, you should update the plugin metadata such as the
plugin name in the `consolePlugin` declaration of package.json.

## Local development

1. `yarn install`
2. `yarn run start`

The server runs on port 9001 with CORS enabled.

See the plugin development section in
[Console Dynamic Plugins README](https://github.com/openshift/console/tree/master/frontend/packages/console-dynamic-plugin-sdk/README.md)
for details on how to run OpenShift console using local plugins.

When a local console server is running, visit <http://localhost:9000/example>
to see the example plugin page.

## Docker image

1. Build the image:
   ```sh
   docker build -t quay.io/my-repositroy/my-plugin:latest .
   ```
2. Run the image:
   ```sh
   docker run -it --rm -d -p 9001:80 quay.io/my-repository/my-plugin:latest
   ```
3. Push the image to the image registry:
   ```sh
   docker push quay.io/my-repository/my-plugin:latest
   ```

## Deployment on cluster

After pushing an image with your changes to an image registry, you can deploy
the plugin to a cluster by instantiating the template:

```sh
oc process -f template.yaml \
  -p PLUGIN_NAME=my-plugin \
  -p NAMESPACE=my-plugin-namespace \
  -p IMAGE=quay.io/my-repository/my-plugin:latest \
  | oc create -f -
```

The `PLUGIN_NAME` value must match the plugin name you used in the
`consolePlugin` declaration of package.json.

Once deployed, patch the
[Console operator](https://github.com/openshift/console-operator)
config to enable the plugin.

```sh
oc patch consoles.operator.openshift.io cluster \
  --patch '{ "spec": { "plugins": ["my-plugin"] } }' --type=merge
```

## References

* [Console Plugin SDK README](https://github.com/openshift/console/tree/master/frontend/packages/console-dynamic-plugin-sdk)
* [Customization Plugin Example](https://github.com/spadgett/console-customization-plugin)
