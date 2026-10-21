import type { Locator, Page } from '@playwright/test';

const AUTH_DISABLED_USERNAME = 'Auth disabled';
export const KUBEADMIN_USERNAME = 'kubeadmin';

export class LoginPage {
  constructor(private readonly page: Page) {}

  // Fill a field via CDP to avoid exposing the value in Playwright traces
  // https://github.com/microsoft/playwright/issues/19992#issuecomment-4078945450
  private async fillSensitive(locator: Locator, text: string) {
    await locator.focus();
    const cdpSession = await this.page.context().newCDPSession(this.page);
    await cdpSession.send('Input.dispatchKeyEvent', {
      type: 'keyDown',
      key: 'a',
      commands: ['selectAll'],
    });
    await cdpSession.send('Input.dispatchKeyEvent', { type: 'keyUp', key: 'a' });
    await cdpSession.send('Input.insertText', { text });
    await cdpSession.detach();
  }

  async login(
    username: string = KUBEADMIN_USERNAME,
    password: string = process.env.BRIDGE_KUBEADMIN_PASSWORD ?? '',
  ) {
    await this.page.context().clearCookies();
    await this.page.goto('/', { timeout: 90_000, waitUntil: 'domcontentloaded' });

    // Wait for either the login form or a console with auth disabled / an existing session.
    await this.page
      .getByTestId('login')
      .or(this.page.getByTestId('username'))
      .first()
      .waitFor({ state: 'visible' });

    if (await this.page.getByTestId('username').isVisible()) {
      return;
    }

    await this.page.locator('#inputUsername').fill(username);
    await this.fillSensitive(this.page.locator('#inputPassword'), password);
    await this.page.locator('button[type=submit]').click();
    await this.page.getByTestId('username').waitFor({ state: 'attached' });
  }

  async logout() {
    // Auth-disabled consoles have no user menu to log out from.
    const username = this.page.getByTestId('username');
    const usernameText = await username.textContent();

    if (usernameText === AUTH_DISABLED_USERNAME) {
      return;
    }

    await username.click();
    await this.page.getByTestId('log-out').waitFor({ state: 'visible' });
    // oxlint-disable-next-line playwright/no-force-option -- dropdown may be covered by overlay
    await this.page.getByTestId('log-out').click({ force: true });
  }
}
