#!/usr/bin/env bash

set -exuo pipefail

ARTIFACT_DIR=${ARTIFACT_DIR:=/tmp/artifacts}
TEST_RESULTS_DIR=integration-tests/results
INSTALLER_DIR=${INSTALLER_DIR:=${ARTIFACT_DIR}/installer}

function copyArtifacts {
  if [ -d "$ARTIFACT_DIR" ] && [ -d "$TEST_RESULTS_DIR" ]; then
    if [[ -z "$(ls -A -- "$TEST_RESULTS_DIR")" ]]; then
      echo "No artifacts were copied."
    else
      echo "Copying artifacts from $(pwd)..."
      cp -r "$TEST_RESULTS_DIR" "${ARTIFACT_DIR}"
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
  yarn install --immutable
fi

echo "Runs Playwright tests in headless mode"
yarn test-e2e-headless
