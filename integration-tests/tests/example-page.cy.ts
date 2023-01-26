import { checkErrors } from '../support';

const PLUGIN_TEMPLATE_NAME = 'console-plugin-template';
const PLUGIN_TEMPLATE_PULL_SPEC = Cypress.env('PLUGIN_TEMPLATE_PULL_SPEC');
export const isLocalDevEnvironment =
  Cypress.config('baseUrl').includes('localhost');

const installHelmChart = (path: string) => {
  cy.exec(
    `cd ../../console-plugin-template && ${path} upgrade -i ${PLUGIN_TEMPLATE_NAME} charts/openshift-console-plugin -n ${PLUGIN_TEMPLATE_NAME} --create-namespace --set plugin.image=${PLUGIN_TEMPLATE_PULL_SPEC}`,
    {
      failOnNonZeroExit: false,
    },
  ).then((result: any) => {
    cy.visit(`/example`);
    cy.log('Error installing helm chart: ', result.stderr);
    cy.log('Successfully installed helm chart: ', result.stdout);
  });
};

const deleteHelmChart = (path: string) => {
  cy.exec(
    `cd ../../console-plugin-template && ${path} uninstall ${PLUGIN_TEMPLATE_NAME} -n ${PLUGIN_TEMPLATE_NAME} && oc delete namespaces ${PLUGIN_TEMPLATE_NAME}`,
    {
      failOnNonZeroExit: false,
    },
  ).then((result: any) => {
    cy.log('Error uninstalling helm chart: ', result.stderr);
    cy.log('Successfully uninstalled helm chart: ', result.stdout);
  });
};

if (!Cypress.env('OPENSHIFT_CI') || Cypress.env('PLUGIN_TEMPLATE_PULL_SPEC')) {
  describe('Console plugin template test', () => {
    before(() => {
      cy.login();

      if (!isLocalDevEnvironment) {
        console.log('this is not a local env, installig helm');

        cy.exec('cd ../../console-plugin-template && ./install_helm.sh', {
          failOnNonZeroExit: false,
        }).then((result) => {
          cy.log('Error installing helm binary: ', result.stderr);
          cy.log(
            'Successfully installed helm binary in "/tmp" directory: ',
            result.stdout,
          );

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
      cy.logout();
      if (!isLocalDevEnvironment) {
        deleteHelmChart('/tmp/helm');
      } else {
        deleteHelmChart('helm');
      }
    });

    it('Verify the url', () => {
      cy.url().should('include', '/example');
    });
    it('Verify the example page title', () => {
      cy.get('[data-test="example-page-title"]').should(
        'contain',
        'Hello, Plugin!',
      );
    });
  });
}
