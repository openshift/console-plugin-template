import type { Locator, Page } from '@playwright/test';

declare global {
  interface Window {
    SERVER_FLAGS?: {
      authDisabled?: boolean;
    };
  }
}

export const KUBEADMIN_USERNAME = 'kubeadmin';

export class LoginPage {
  constructor(private readonly page: Page) {}

  private async isAuthDisabled() {
    return this.page.evaluate(() => window.SERVER_FLAGS?.authDisabled);
  }

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
    await this.page.goto('/');

    if (await this.isAuthDisabled()) {
      return;
    }

    await this.page.locator('[data-test-id="login"]').waitFor({ state: 'visible' });
    await this.page.locator('#inputUsername').fill(username);
    await this.fillSensitive(this.page.locator('#inputPassword'), password);
    await this.page.locator('button[type=submit]').click();
    await this.page.getByTestId('username').waitFor({ state: 'attached' });
  }

  async logout() {
    if (await this.isAuthDisabled()) {
      return;
    }
    await this.page.getByTestId('username').click();
    await this.page.getByTestId('log-out').waitFor({ state: 'visible' });
    // eslint-disable-next-line playwright/no-force-option -- dropdown may be covered by overlay
    await this.page.getByTestId('log-out').click({ force: true });
  }
}
