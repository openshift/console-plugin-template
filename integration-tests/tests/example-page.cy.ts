import { checkErrors } from '../support';

const PLUGIN_TEMPLATE_NAME = 'console-plugin-template';
const PLUGIN_TEMPLATE_PULL_SPEC = Cypress.env('PLUGIN_TEMPLATE_PULL_SPEC');
// We know that the baseUrl is always set because it's in the cypress config
// eslint-disable-next-line @typescript-eslint/no-non-null-assertion
export const isLocalDevEnvironment = Cypress.config('baseUrl')!.includes('localhost');

const installHelmChart = (path: string) => {
  cy.exec(
    `cd ../../console-plugin-template && ${path} upgrade -i ${PLUGIN_TEMPLATE_NAME} charts/openshift-console-plugin -n ${PLUGIN_TEMPLATE_NAME} --create-namespace --set plugin.image=${PLUGIN_TEMPLATE_PULL_SPEC}`,
    {
      failOnNonZeroExit: false,
    },
  ).then((result) => {
    result.stderr && cy.log('Error installing helm chart: ', result.stderr);
    result.stdout && cy.log('Successfully installed helm chart: ', result.stdout);
    cy.visit('/k8s/cluster/operator.openshift.io~v1~Console/cluster/console-plugins');
    cy.get('[data-test="console-plugin-template-status"]').should('include.text', 'loaded');
  });
};
const deleteHelmChart = (path: string) => {
  cy.exec(
    `cd ../../console-plugin-template && ${path} uninstall ${PLUGIN_TEMPLATE_NAME} -n ${PLUGIN_TEMPLATE_NAME} && oc delete namespaces ${PLUGIN_TEMPLATE_NAME}`,
    {
      failOnNonZeroExit: false,
    },
  ).then((result) => {
    cy.log('Error uninstalling helm chart: ', result.stderr);
    cy.log('Successfully uninstalled helm chart: ', result.stdout);
  });
};

describe('Console plugin template test', () => {
  before(() => {
    cy.login();
    cy.get(`[data-test="tour-step-footer-secondary"]`).contains('Skip tour').click();
    if (!isLocalDevEnvironment) {
      console.log('this is not a local env, installig helm');

      cy.exec('cd ../../console-plugin-template && ./install_helm.sh', {
        failOnNonZeroExit: false,
      }).then((result) => {
        cy.log('Error installing helm binary: ', result.stderr);
        cy.log('Successfully installed helm binary in "/tmp" directory: ', result.stdout);

        installHelmChart('/tmp/helm');
      });
    } else {
      console.log('this is a local env, not installing helm');

      installHelmChart('helm');
    }
  });

  afterEach(() => {
    checkErrors();
  });

  after(() => {
    if (!isLocalDevEnvironment) {
      deleteHelmChart('/tmp/helm');
    } else {
      deleteHelmChart('helm');
    }
    cy.logout();
  });

  it('Verify the example page title', () => {
    cy.get('[data-quickstart-id="qs-nav-home"]').click();
    cy.get('[data-test="nav"]').contains('Plugin example').click();
    cy.url().should('include', '/example');
    cy.get('title').should('contain', 'Hello, plugin!');
  });
});
