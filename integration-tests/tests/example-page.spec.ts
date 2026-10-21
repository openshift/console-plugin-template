import { expect, test } from '@playwright/test';
import { checkErrors } from '../support';
import { execSync } from 'node:child_process';

const PLUGIN_TEMPLATE_NAME = 'console-plugin-template';

const isLocalDevEnvironment = (process.env.BRIDGE_BASE_ADDRESS ?? 'http://localhost:9000').includes(
  'localhost',
);

const exec = (command: string, timeoutMs = 360_000) => {
  try {
    return execSync(command, { timeout: timeoutMs, encoding: 'utf8' });
  } catch (error) {
    console.error('Command failed:', command, error);
    return '';
  }
};

const installHelmChart = (helmPath: string) => {
  if (!process.env.PLUGIN_TEMPLATE_PULL_SPEC) {
    console.log('PLUGIN_TEMPLATE_PULL_SPEC not set, skipping helm install');
    return;
  }

  const result = exec(
    `${helmPath} upgrade -i ${PLUGIN_TEMPLATE_NAME} charts/openshift-console-plugin -n ${PLUGIN_TEMPLATE_NAME} --create-namespace --set plugin.image=${process.env.PLUGIN_TEMPLATE_PULL_SPEC}`,
  );
  console.log('Helm install:', result);

  exec(
    `oc rollout status -n ${PLUGIN_TEMPLATE_NAME} deploy/${PLUGIN_TEMPLATE_NAME} -w --timeout=300s`,
  );
  exec('oc rollout status -w deploy/console -n openshift-console --timeout=300s');
};

const deleteHelmChart = (helmPath: string) => {
  const result = exec(
    `${helmPath} uninstall ${PLUGIN_TEMPLATE_NAME} -n ${PLUGIN_TEMPLATE_NAME} && oc delete namespaces ${PLUGIN_TEMPLATE_NAME}`,
  );
  console.log('Helm uninstall:', result);
};

test.describe('Console plugin template test', () => {
  test.beforeAll(() => {
    if (isLocalDevEnvironment) {
      console.log('this is a local env, not installing helm');
      installHelmChart('helm');
    } else {
      console.log('this is not a local env, installing helm');
      exec('./install_helm.sh');
      installHelmChart('/tmp/helm');
    }
  });

  test.afterEach(async ({ page }) => {
    await checkErrors(page);
  });

  test.afterAll(() => {
    if (isLocalDevEnvironment) {
      deleteHelmChart('helm');
    } else {
      deleteHelmChart('/tmp/helm');
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
