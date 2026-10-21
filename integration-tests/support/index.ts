import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';

export const checkErrors = async (page: Page) => {
  const windowError = await page.evaluate(
    () => (window as Window & { windowError?: string }).windowError,
  );
  expect(windowError, 'Console JS error detected').toBeUndefined();
};
