#!/usr/bin/env bash

set -exuo pipefail

ARTIFACT_DIR=${ARTIFACT_DIR:=/tmp/artifacts}
SCREENSHOTS_DIR=integration-tests/screenshots
INSTALLER_DIR=${INSTALLER_DIR:=${ARTIFACT_DIR}/installer}
NS=console-plugin-template

function copyArtifacts {
  oc get deployments -n ${NS} -o wide > ${ARTIFACT_DIR}/deployment_details.yaml
  oc get deployments -n ${NS} -o yaml >> ${ARTIFACT_DIR}/deployment_details.yaml
  oc get console.v1.operator.openshift.io cluster -o yaml >> ${ARTIFACT_DIR}/cluster.yaml

  for pod in `oc get pods -n ${NS} --no-headers -o custom-columns=":metadata.name"`; do
        echo $pod 
        oc logs $pod -n ${NS} > ${ARTIFACT_DIR}/${pod}.logs
  done
  
  if [ -d "$ARTIFACT_DIR" ] && [ -d "$SCREENSHOTS_DIR" ]; then
    if [[ -z "$(ls -A -- "$SCREENSHOTS_DIR")" ]]; then
      echo "No artifacts were copied."
    else
      echo "Copying artifacts from $(pwd)..."
      cp -r "$SCREENSHOTS_DIR" "${ARTIFACT_DIR}/screenshots"
    fi
  fi
}

trap copyArtifacts EXIT


# don't log kubeadmin-password
set +x
BRIDGE_KUBEADMIN_PASSWORD="$(cat "${KUBEADMIN_PASSWORD_FILE:-${INSTALLER_DIR}/auth/kubeadmin-password}")"
export BRIDGE_KUBEADMIN_PASSWORD
set -x
BRIDGE_BASE_ADDRESS="$(oc get consoles.config.openshift.io cluster -o jsonpath='{.status.consoleURL}')"
export BRIDGE_BASE_ADDRESS

echo "Install dependencies"
if [ ! -d node_modules ]; then
  yarn install
fi

# echo "Install Helm"
# ./install_helm.sh

# echo "ENV"
# env

echo "Runs Cypress tests in headless mode"
yarn run test-cypress-headless