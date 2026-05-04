import { test as setup } from '@playwright/test';
import { LoginPage } from '../pages/login';

// eslint-disable-next-line playwright/expect-expect -- setup test saves storageState, no assertions needed
setup('authenticate', async ({ page }) => {
  const loginPage = new LoginPage(page);
  await loginPage.login();

  await page.getByTestId('tour-step-footer-secondary').filter({ hasText: 'Skip tour' }).click();

  await page.context().storageState({ path: 'integration-tests/.auth/user.json' });
});
