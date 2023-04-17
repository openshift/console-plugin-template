#!/usr/bin/env bash

set -exuo pipefail

ARTIFACT_DIR=${ARTIFACT_DIR:=/tmp/artifacts}
SCREENSHOTS_DIR=integration-tests/screenshots
INSTALLER_DIR=${INSTALLER_DIR:=${ARTIFACT_DIR}/installer}

function copyArtifacts {
  oc cluster-info dump > ${ARTIFACT_DIR}/cluster_info.json
  oc get secrets -A -o wide > ${ARTIFACT_DIR}/secrets.yaml
  oc get secrets -A -o yaml >> ${ARTIFACT_DIR}/secrets.yaml
  oc get catalogsource -A -o wide > ${ARTIFACT_DIR}/catalogsource.yaml
  oc get catalogsource -A -o yaml >> ${ARTIFACT_DIR}/catalogsource.yaml
  oc get subscriptions -n ${NS} -o wide > ${ARTIFACT_DIR}/subscription_details.yaml
  oc get subscriptions -n ${NS} -o yaml >> ${ARTIFACT_DIR}/subscription_details.yaml
  oc get csvs -n ${NS} -o wide > ${ARTIFACT_DIR}/csvs.yaml
  oc get csvs -n ${NS} -o yaml >> ${ARTIFACT_DIR}/csvs.yaml
  oc get deployments -n ${NS} -o wide > ${ARTIFACT_DIR}/deployment_details.yaml
  oc get deployments -n ${NS} -o yaml >> ${ARTIFACT_DIR}/deployment_details.yaml
  oc get installplan -n ${NS} -o wide > ${ARTIFACT_DIR}/installplan.yaml
  oc get installplan -n ${NS} -o yaml >> ${ARTIFACT_DIR}/installplan.yaml
  oc get nodes -o wide > ${ARTIFACT_DIR}/node.yaml
  oc get nodes -o yaml >> ${ARTIFACT_DIR}/node.yaml
  for pod in `oc get pods -n ${NS} --no-headers -o custom-columns=":metadata.name"; do
        echo $pod 
        oc logs $pod -n ${NS} > ${ARTIFACT_DIR}/${pod}.logs
  done
  oc get serviceaccounts -n ${NS} -o wide > ${ARTIFACT_DIR}/serviceaccount.yaml
  oc get serviceaccounts -n ${NS} -o yaml >> ${ARTIFACT_DIR}/serviceaccount.yaml
  oc get console.v1.operator.openshift.io cluster -o yaml >> ${ARTIFACT_DIR}/cluster.yaml
  
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

echo "Runs Cypress tests in headless mode"
yarn run test-cypress-headless