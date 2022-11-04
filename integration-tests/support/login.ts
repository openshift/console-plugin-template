import { submitButton } from '../views/form';
import { masthead } from '../views/masthead';

declare global {
  namespace Cypress {
    interface Chainable {
      login(
        providerName?: string,
        username?: string,
        password?: string,
      ): Chainable<Element>;
      logout(): Chainable<Element>;
    }
  }
}

const KUBEADMIN_USERNAME = 'kubeadmin';

// any command added below, must be added to global Cypress interface above

// This will add 'cy.login(...)'
// ex: cy.login('my-idp', 'my-user', 'my-password')
Cypress.Commands.add(
  'login',
  (provider: string, username: string, password: string) => {
    // Check if auth is disabled (for a local development environment).
    cy.visit('http://localhost:9000/dashboards'); // visits baseUrl which is set in plugins/index.js
    cy.window().then((win: any) => {
      if (win.SERVER_FLAGS?.authDisabled) {
        return;
      }

      // Make sure we clear the cookie in case a previous test failed to logout.
      cy.clearCookie('openshift-session-token');

      cy.get('#inputUsername').type(username || KUBEADMIN_USERNAME);
      cy.get('#inputPassword').type(
        password || Cypress.env('BRIDGE_KUBEADMIN_PASSWORD'),
      );
      cy.get(submitButton).click();
      masthead.username.shouldBeVisible();
    });
  },
);

Cypress.Commands.add('logout', () => {
  // Check if auth is disabled (for a local development environment).
  cy.window().then((win: any) => {
    if (win.SERVER_FLAGS?.authDisabled) {
      return;
    }
    cy.get('[data-test="user-dropdown"]').click();
    cy.get('[data-test="log-out"]').should('be.visible');
    cy.get('[data-test="log-out"]').click({ force: true });
  });
});
