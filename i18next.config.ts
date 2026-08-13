import { readFile } from 'node:fs/promises';
import jsonc from 'comment-json';
import { defineConfig, Plugin } from 'i18next-cli';
import { consolePlugin as consolePluginMetadata } from './package.json';

const EXPECTED_NAMESPACE = `plugin__${consolePluginMetadata.name}`;

/**
 * Custom JSON parser for localizing keys matching format: /%.+%/
 */
const consoleExtensionsPlugin = (): Plugin => ({
  name: 'console-extensions',

  async onEnd(keys) {
    const content = await readFile('console-extensions.json', 'utf-8');
    const extracted: { key: string }[] = [];

    try {
      jsonc.parse(
        content,
        (_key, value) => {
          if (typeof value === 'string') {
            const match = value.match(/^%(.+)%$/);
            if (match && match[1]) {
              extracted.push({ key: match[1] });
            }
          }
          return value;
        },
        true,
      );
    } catch (e) {
      console.error('Failed to parse as JSON.', e);
      extracted.length = 0;
    }

    for (const { key: fullKey } of extracted) {
      const sep = fullKey.indexOf('~');
      if (sep > 0 && sep < fullKey.length - 1) {
        const ns = fullKey.slice(0, sep);
        const key = fullKey.slice(sep + 1);
        keys.set(`${ns}:${key}`, { key, defaultValue: key, ns });
      } else {
        console.warn(`Invalid key format: ${fullKey}`);
      }
    }

    // Validate keys have the correct namespace
    const mismatchedKeys = [...keys.entries()].filter(([fullKey, { ns }]) => {
      const fullNs = fullKey.split(':')[0];
      return !ns || fullNs !== EXPECTED_NAMESPACE;
    }).map(([fullKey]) => fullKey);
    if (mismatchedKeys.length > 0) {
      throw new Error(
        `Found ${mismatchedKeys.length} keys with mismatched namespace. Expected namespace: ${EXPECTED_NAMESPACE}
${mismatchedKeys.map((key) => `  - ${key}`).join('\n')}`,
      );
    }
  },
});

export default defineConfig({
  locales: ['en'],
  extract: {
    input: 'src/**/*.{js,jsx,ts,tsx}',
    output: 'locales/{{language}}/{{namespace}}.json',

    defaultValue: (key) => key.replace(/_(?:one|other)$/, ''),
    sort: true,
    keySeparator: false,
    nsSeparator: '~',
    defaultNS: EXPECTED_NAMESPACE,
  },
  plugins: [consoleExtensionsPlugin()],
});
