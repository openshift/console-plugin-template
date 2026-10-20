import { defineConfig } from '@playwright/test';
import { join } from 'node:path';

const artifactDir: string = process.env.ARTIFACT_DIR ?? 'integration-tests/results';

export default defineConfig({
  testDir: './integration-tests/tests',
  outputDir: join(artifactDir, 'test-results'),
  timeout: 30_000,
  retries: 1,
  use: {
    baseURL: process.env.BRIDGE_BASE_ADDRESS ?? 'http://localhost:9000',
    viewport: { width: 1920, height: 1080 },
    screenshot: 'on',
    ignoreHTTPSErrors: true,
    video: 'retain-on-failure',
    trace: 'on',
    testIdAttribute: 'data-test',
  },
  projects: [
    { name: 'setup', testMatch: /auth\.setup\.ts/ },
    {
      name: 'chromium',
      use: {
        browserName: 'chromium',
        storageState: 'integration-tests/.auth/user.json',
      },
      dependencies: ['setup'],
    },
  ],
  reporter: [
    ['list'],
    ['html', { outputFolder: join(artifactDir, 'html'), open: 'never' }],
    ['junit', { outputFile: join(artifactDir, 'junit-results.xml') }],
  ],
});
