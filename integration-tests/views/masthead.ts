export const masthead = {
  username: {
    shouldBeVisible: () =>
      cy
        .get(
          `[data-test=${Cypress.env(
            'BRIDGE_KUBEADMIN_PASSWORD',
          )} ? 'user-dropdown' : 'username'`,
        )
        .should('be.visible'),
    shouldHaveText: (text: string) =>
      cy
        .get(
          `[data-test=${Cypress.env(
            'BRIDGE_KUBEADMIN_PASSWORD',
          )} ? 'user-dropdown' : 'username'`,
        )
        .should('have.text', text),
  },
  clickMastheadLink: (path: string) => {
    return cy.get(`[data-test=${path}`).click();
  },
};
