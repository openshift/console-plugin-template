import { execSync } from 'child_process';
import { test, expect } from '@playwright/test';
import { checkErrors } from '../support';

const PLUGIN_TEMPLATE_NAME = 'console-plugin-template';
// Defined in openshift/release ci-operator config as CYPRESS_PLUGIN_TEMPLATE_PULL_SPEC
const PLUGIN_TEMPLATE_PULL_SPEC =
  process.env.PLUGIN_TEMPLATE_PULL_SPEC ?? process.env.CYPRESS_PLUGIN_TEMPLATE_PULL_SPEC;

const isLocalDevEnvironment = (process.env.BRIDGE_BASE_ADDRESS ?? 'http://localhost:9000').includes(
  'localhost',
);

function exec(command: string, timeoutMs = 360000) {
  try {
    return execSync(command, { timeout: timeoutMs, encoding: 'utf-8' });
  } catch (e) {
    console.error('Command failed:', command, e);
    return '';
  }
}

function installHelmChart(helmPath: string) {
  const result = exec(
    `${helmPath} upgrade -i ${PLUGIN_TEMPLATE_NAME} charts/openshift-console-plugin -n ${PLUGIN_TEMPLATE_NAME} --create-namespace --set plugin.image=${PLUGIN_TEMPLATE_PULL_SPEC}`,
  );
  console.log('Helm install:', result);

  exec(
    `oc rollout status -n ${PLUGIN_TEMPLATE_NAME} deploy/${PLUGIN_TEMPLATE_NAME} -w --timeout=300s`,
  );
  exec('oc rollout status -w deploy/console -n openshift-console --timeout=300s');
}

function deleteHelmChart(helmPath: string) {
  const result = exec(
    `${helmPath} uninstall ${PLUGIN_TEMPLATE_NAME} -n ${PLUGIN_TEMPLATE_NAME} && oc delete namespaces ${PLUGIN_TEMPLATE_NAME}`,
  );
  console.log('Helm uninstall:', result);
}

test.describe('Console plugin template test', () => {
  test.beforeAll(() => {
    if (!isLocalDevEnvironment) {
      console.log('this is not a local env, installing helm');
      exec('./install_helm.sh');
      installHelmChart('/tmp/helm');
    } else {
      console.log('this is a local env, not installing helm');
      installHelmChart('helm');
    }
  });

  test.afterEach(async ({ page }) => {
    await checkErrors(page);
  });

  test.afterAll(() => {
    if (!isLocalDevEnvironment) {
      deleteHelmChart('/tmp/helm');
    } else {
      deleteHelmChart('helm');
    }
  });

  test('Verify the example page title', async ({ page }) => {
    await page.goto('/');
    await page.locator('[data-quickstart-id="qs-nav-home"]').click();
    await page.getByTestId('nav').getByText('Plugin example').click();
    await expect(page).toHaveURL(/\/example/);
    await expect(page).toHaveTitle(/Hello, plugin!/);
  });
});
