#!/usr/bin/env bash

set -exuo pipefail

INSTALLER_DIR=${INSTALLER_DIR:=${ARTIFACT_DIR:-/tmp/artifacts}/installer}

# don't log kubeadmin-password
set +x
BRIDGE_KUBEADMIN_PASSWORD="$(cat "${KUBEADMIN_PASSWORD_FILE:-${INSTALLER_DIR}/auth/kubeadmin-password}")"
export BRIDGE_KUBEADMIN_PASSWORD
set -x
BRIDGE_BASE_ADDRESS="$(oc get consoles.config.openshift.io cluster -o jsonpath='{.status.consoleURL}')"
export BRIDGE_BASE_ADDRESS

echo "Disable guided tour"
oc patch console.operator.openshift.io cluster --type=merge -p '{"spec":{"customization":{"capabilities":[{"name":"GuidedTour","visibility":{"state":"Disabled"}}]}}}'
oc rollout status -w deploy/console -n openshift-console --timeout=300s

echo "Install dependencies"
if [ ! -d node_modules ]; then
  yarn install --immutable
fi

export PLAYWRIGHT_BROWSERS_PATH="/tmp/playwright"

echo "Install Chromium for Playwright"
yarn playwright install chromium

echo "Runs Playwright tests in headless mode"
yarn test-e2e-headless
