import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';
import react from 'eslint-plugin-react';
import prettier from 'eslint-plugin-prettier/recommended';
import reactHooks from 'eslint-plugin-react-hooks';
import importX from 'eslint-plugin-import-x';
import { createTypeScriptImportResolver } from 'eslint-import-resolver-typescript';
import playwright from 'eslint-plugin-playwright';
import jest from 'eslint-plugin-jest';
import testingLibrary from 'eslint-plugin-testing-library';
import globals from 'globals';

export default tseslint.config(
  {
    ignores: ['dist/', 'node_modules/'],
  },
  eslint.configs.recommended,
  tseslint.configs.strictTypeChecked,
  tseslint.configs.stylisticTypeChecked,
  reactHooks.configs.flat['recommended-latest'],
  importX.flatConfigs.recommended,
  importX.flatConfigs.typescript,
  {
    settings: {
      'import-x/resolver-next': [createTypeScriptImportResolver()],
    },
  },
  {
    files: ['src/**/*.{ts,tsx}'],
    plugins: {
      react,
    },
    rules: {
      ...react.configs.recommended.rules,
      ...react.configs['jsx-runtime'].rules,
      '@typescript-eslint/consistent-type-imports': 'error',
    },
    languageOptions: {
      globals: globals.browser,
      parserOptions: {
        projectService: true,
        ecmaFeatures: {
          jsx: true,
        },
      },
    },
    settings: {
      react: {
        version: 'detect',
      },
    },
  },
  {
    files: ['src/**/*.spec.{ts,tsx}'],
    plugins: {
      ...jest.configs['flat/recommended'].plugins,
      ...jest.configs['flat/style'].plugins,
      ...testingLibrary.configs['flat/react'].plugins,
    },
    languageOptions: {
      ...jest.configs['flat/recommended'].languageOptions,
      ...jest.configs['flat/style'].languageOptions,
      globals: {
        ...jest.configs['flat/recommended'].languageOptions?.globals,
        ...globals.node,
      },
    },
    rules: {
      ...jest.configs['flat/recommended'].rules,
      ...jest.configs['flat/style'].rules,
      ...testingLibrary.configs['flat/react'].rules,
    },
  },
  {
    ...playwright.configs['flat/recommended'],
    files: ['integration-tests/**/*.ts'],
    ...tseslint.configs.disableTypeChecked,
    rules: {
      ...playwright.configs['flat/recommended'].rules,
      ...tseslint.configs.disableTypeChecked.rules,
      'no-console': 'off',
    },
  },
  prettier,
);
