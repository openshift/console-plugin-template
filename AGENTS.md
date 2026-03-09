# AI Agent Instructions for OpenShift Console Plugin Template

This document provides context and guidelines for AI coding assistants working on this codebase.

## Project Overview

This is a **template repository** for creating OpenShift Console dynamic plugins. It's meant to be used via GitHub's "Use this template" feature, NOT forked. The template provides a minimal starting point for extending the OpenShift Console UI with custom pages and functionality.

> **⚠️ WARNING:**
> This repository is used by multiple large-scale enterprise web applications. Please proceed with caution when making any changes to this codebase. Changes here can affect downstream projects that depend on this template.
>
> **Only make changes that should be standard practice for ALL plugins created from this template.** If a change is specific to one plugin use case, it belongs in the instantiated plugin repository, not in this template.

**Key Technologies:**
- TypeScript + React 17
- PatternFly 6 (UI component library)
- Webpack 5 with Module Federation
- react-i18next for internationalization
- Cypress for e2e testing
- Helm for deployment

**Compatibility:** Requires OpenShift 4.12+ (uses ConsolePlugin CRD v1 API)

## Architecture & Patterns

### Dynamic Plugin System

This plugin uses webpack module federation to load at runtime into the OpenShift Console. Key files:

- `console-extensions.json`: Declares what the plugin adds to console (routes, nav items, etc.)
- `package.json` `consolePlugin` section: Plugin metadata and exposed modules mapping
- `webpack.config.ts`: Configures module federation and build

**Critical:** Any component referenced in `console-extensions.json` must have a corresponding entry in `package.json` under `consolePlugin.exposedModules`.

### Component Structure

- Use functional components with hooks (NO class components)
- All components should be TypeScript (`.tsx`)
- Follow PatternFly component patterns
- Use PatternFly CSS variables instead of hex colors (dark mode compatibility)

### Styling Constraints

**IMPORTANT:** The `.stylelintrc.yaml` enforces strict rules to prevent breaking console:

- **NO hex colors** - use PatternFly CSS variables (e.g., `var(--pf-v6-global-palette--blue-500)`)
- **NO naked element selectors** (like `table`, `div`) - prevents overwriting console styles
- **NO `.pf-` or `.co-` prefixed classes** - these are reserved for PatternFly and console
- **Prefix all custom classes** with plugin name (e.g., `console-plugin-template__nice`)

Don't disable these rules without understanding they protect against layout breakage!

## Internationalization (i18n)

**Namespace Convention:** `plugin__<plugin-name>` (e.g., `plugin__console-plugin-template`)

### In React Components:
```tsx
const { t } = useTranslation('plugin__console-plugin-template');
return <h1>{t('Hello, World!')}</h1>;
```

### In console-extensions.json:
```json
"name": "%plugin__console-plugin-template~My Label%"
```

**After adding/changing messages:** Run `yarn i18n` to update locale files in `/locales`

## File Organization

```
src/
  components/          # React components
    ExamplePage.tsx   # Example page component
    *.css            # Component styles (scoped with plugin prefix)
console-extensions.json # Plugin extension declarations
package.json           # Plugin metadata in consolePlugin section
tsconfig.json          # TypeScript config (strict: false currently)
webpack.config.ts      # Module federation + build config
locales/               # i18n translation files
charts/                # Helm chart for deployment
integration-tests/     # Cypress e2e tests
```

## Development Workflow

### Local Development
1. `yarn install` - install dependencies
2. `yarn start` - starts webpack dev server on port 9001 with CORS
3. `yarn start-console` - runs OpenShift console in container (requires cluster login)
4. Navigate to http://localhost:9000/example

### Code Quality
- `yarn lint` - runs eslint, prettier, and stylelint (with --fix)
- Linting is mandatory before commits
- Follow existing code patterns in the repo

### Testing
- `yarn test-cypress` - opens Cypress UI
- `yarn test-cypress-headless` - runs Cypress in CI mode
- Add e2e tests for new pages/features

## TypeScript Configuration

Current config has `strict: false` but enforces:
- `noUnusedLocals: true`
- All files should use `.tsx` extension
- Target: ES2020

**Modernization opportunity:** When touching files, consider enabling stricter TypeScript checks.

## Common Development Tasks

### Adding a New Page
1. Create component in `src/components/MyPage.tsx`
2. Add to `package.json` `exposedModules`: `"MyPage": "./components/MyPage"`
3. Add route in `console-extensions.json`:
   ```json
   {
     "type": "console.page/route",
     "properties": {
       "path": "/my-page",
       "component": { "$codeRef": "MyPage" }
     }
   }
   ```
4. Optional: Add nav item in `console-extensions.json`
5. Run `yarn i18n` if you added translatable strings

### Adding a Navigation Item
```json
{
  "type": "console.navigation/href",
  "properties": {
    "id": "my-nav-item",
    "name": "%plugin__console-plugin-template~My Page%",
    "href": "/my-page",
    "perspective": "admin",
    "section": "home"
  }
}
```

### Updating Plugin Name
When instantiating from template, update:
1. `package.json` - `name` and `consolePlugin.name`
2. `package.json` - `consolePlugin.displayName` and `description`
3. All i18n namespace references (`plugin__<name>`)
4. CSS class prefixes
5. Helm chart values

## Build & Deployment

### Building Image
```bash
docker build -t quay.io/my-repository/my-plugin:latest .
# For Apple Silicon: add --platform=linux/amd64
```

### Deploying via Helm
```bash
helm upgrade -i my-plugin charts/openshift-console-plugin \
  -n my-namespace \
  --create-namespace \
  --set plugin.image=my-plugin-image-location
```

**Note:** OpenShift 4.10 requires `--set plugin.securityContext.enabled=false`

## Important Constraints & Gotchas

1. **Template, not fork:** Users should use "Use this template", not fork
2. **i18n namespace must match ConsolePlugin resource name** with `plugin__` prefix
3. **CSS class prefixes prevent style conflicts** - always prefix with plugin name
4. **Module federation requires exact module mapping** - `exposedModules` must match `$codeRef` values
5. **PatternFly CSS variables only** - hex colors break dark mode
6. **No webpack HMR for extensions** - changes to `console-extensions.json` require restart
7. **TypeScript not in strict mode** - legacy choice, can be modernized
8. **React 17, not 18** - matches console's React version

## Extension Points

See [Console Plugin SDK README](https://github.com/openshift/console/tree/master/frontend/packages/console-dynamic-plugin-sdk) for available extension types:

- `console.page/route` - add new pages
- `console.navigation/href` - add nav items
- `console.navigation/section` - add nav sections
- `console.tab` - add tabs to resource pages
- `console.action/provider` - add actions to resources
- `console.flag` - feature flags
- Many more...

## Code Style Preferences

- Functional components with hooks (NO classes)
- TypeScript for all new files
- Use PatternFly components whenever possible
- Keep components focused and composable
- Prefer named exports for components
- Use `React.FC` or explicit return types
- CSS-in-files (not CSS-in-JS)

## Testing Strategy

- **E2E tests (Cypress):** For user flows and page rendering
- **Component tests:** Add when components have complex logic
- **Test data attributes:** Use `data-test` attributes for selectors
- Run tests locally before opening PRs

## References

- [Console Plugin SDK](https://github.com/openshift/console/tree/master/frontend/packages/console-dynamic-plugin-sdk)
- [PatternFly React](https://www.patternfly.org/get-started/develop)
- [Dynamic Plugin Enhancement Proposal](https://github.com/openshift/enhancements/blob/master/enhancements/console/dynamic-plugins.md)

## Quick Decision Guide

**When should I...**

- **Use this template?** When creating a NEW OpenShift Console plugin from scratch
- **Add a page?** Update console-extensions.json + exposedModules + create component
- **Style something?** Use PatternFly components and CSS variables, prefix custom classes
- **Add translations?** Use `t()` function, run `yarn i18n` after
- **Test changes?** Run locally with `yarn start` + `yarn start-console`, add Cypress tests
- **Deploy?** Build image, push to registry, install via Helm chart
