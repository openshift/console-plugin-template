import { expect, test as setup } from '@playwright/test';
import { LoginPage } from '../pages/login';

setup('authenticate', async ({ page }) => {
  const loginPage = new LoginPage(page);
  await loginPage.login();

  await expect(page.getByTestId('username')).toBeVisible({ timeout: 30_000 });

  await page.context().storageState({ path: 'integration-tests/.auth/user.json' });
});
