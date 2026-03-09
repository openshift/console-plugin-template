declare global {
  namespace Cypress {
    interface Chainable {
      login(username?: string, password?: string): Chainable<Element>;
      logout(): Chainable<Element>;
    }
  }
  interface Window {
    SERVER_FLAGS?: {
      authDisabled?: boolean;
    };
  }
}

export const KUBEADMIN_USERNAME = 'kubeadmin';

// This will add 'cy.login(...)'
// ex: cy.login('my-user', 'my-password')
Cypress.Commands.add(
  'login',
  (
    username: string = KUBEADMIN_USERNAME,
    password: string = Cypress.env('BRIDGE_KUBEADMIN_PASSWORD'),
  ) => {
    const baseURL = Cypress.config('baseUrl')!;

    // Make sure we clear the cookie in case a previous test failed to logout.
    cy.clearCookie('openshift-session-token');

    cy.visit(baseURL);

    cy.session(
      username,
      () => {
        // Check if auth is disabled (for a local development environment).
        cy.window().then((win) => {
          if (win.SERVER_FLAGS?.authDisabled) {
            return;
          }
        });

        cy.visit(baseURL);

        cy.get('[data-test-id="login"]').should('be.visible');
        cy.get('#inputUsername').type(username);
        cy.get('#inputPassword').type(password);
        cy.get('button[type=submit]').click();
      },
      {
        cacheAcrossSpecs: true,
        validate() {
          cy.visit(baseURL);
          cy.get('[data-test="username"]').should('exist');
        },
      },
    );
  },
);

Cypress.Commands.add('logout', () => {
  // Check if auth is disabled (for a local development environment).
  cy.window().then((win) => {
    if (win.SERVER_FLAGS?.authDisabled) {
      return;
    }
    cy.get('[data-test="username"]').click();
    cy.get('[data-test="log-out"]').should('be.visible');
    cy.get('[data-test="log-out"]').click({ force: true });
  });
});
