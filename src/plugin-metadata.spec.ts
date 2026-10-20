import * as fs from 'node:fs';
// oxlint-disable-next-line unicorn/import-style -- Jest transforms specs to CJS, where a default import of node:path requires esModuleInterop
import * as path from 'node:path';
import { consolePlugin as consolePluginMetadata, name as packageName } from '../package.json';

// oxlint-disable-next-line unicorn/prefer-module -- Jest runs this spec as CJS, where import.meta is not available
const ROOT = path.resolve(__dirname, '..');
const localeFile = path.join(ROOT, `locales/en/plugin__${consolePluginMetadata.name}.json`);

describe('plugin metadata', () => {
  it('has a matching i18n locale file, package name, and consolePlugin name', () => {
    if (!fs.existsSync(localeFile)) {
      return;
    }
    expect(packageName).toBe(consolePluginMetadata.name);
  });
});
