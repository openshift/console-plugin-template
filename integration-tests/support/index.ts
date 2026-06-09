import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';

export async function checkErrors(page: Page) {
  const windowError = await page.evaluate(
    () => (window as Window & { windowError?: string }).windowError,
  );
  expect(windowError, 'Console JS error detected').toBeUndefined();
}
