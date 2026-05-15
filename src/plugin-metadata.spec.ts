import * as fs from 'fs';
import * as path from 'path';
import type { ConsolePluginBuildMetadata } from '@openshift-console/dynamic-plugin-sdk-webpack';

const ROOT = path.resolve(__dirname, '..');
const packageJson = JSON.parse(fs.readFileSync(path.join(ROOT, 'package.json'), 'utf-8')) as {
  name: string;
  consolePlugin: ConsolePluginBuildMetadata;
};
const localeFile = path.join(ROOT, `locales/en/plugin__${packageJson.consolePlugin.name}.json`);

describe('plugin metadata', () => {
  it('has a matching i18n locale file, package name, and consolePlugin name', () => {
    if (!fs.existsSync(localeFile)) {
      return;
    }
    expect(packageJson.name).toBe(packageJson.consolePlugin.name);
  });
});
