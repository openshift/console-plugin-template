---
name: openshift-console-plugin-setup
description: Project setup, dependencies, and version compatibility for OpenShift Console plugins
---

# OpenShift Console Plugin Setup

This skill provides guidance for setting up OpenShift Console plugin projects, managing dependencies, and ensuring version compatibility. This is the foundation for all console plugin development.

## Project Structure and Setup

### Essential Files and Directories
```
my-console-plugin/
├── src/
│   ├── components/          # React components
│   ├── types/              # TypeScript type definitions
│   └── index.ts            # Entry point
├── console-extensions.json  # Plugin extension declarations
├── package.json            # Dependencies and plugin metadata
├── webpack.config.ts       # Module federation configuration
├── tsconfig.json          # TypeScript configuration
├── locales/               # i18n translation files
├── charts/                # Helm chart for deployment
└── integration-tests/     # Cypress e2e tests
```

### Plugin Metadata in package.json

```json
{
  "name": "@my-org/my-console-plugin",
  "consolePlugin": {
    "name": "my-console-plugin",
    "version": "1.0.0",
    "displayName": "My Console Plugin",
    "description": "Extends OpenShift Console with custom functionality",
    "exposedModules": {
      "MyPage": "./components/MyPage",
      "MyListPage": "./components/MyListPage",
      "MyDetailsPage": "./components/MyDetailsPage"
    },
    "dependencies": {
      "@console/pluginAPI": "^4.21.0"
    }
  }
}
```

## OpenShift Version Compatibility

**⚠️ CRITICAL: Version compatibility is essential for plugin stability**

Plugin development requires careful attention to OpenShift Console and shared library versions. Always reference the [official SDK documentation](https://github.com/openshift/console/blob/main/frontend/packages/console-dynamic-plugin-sdk/README.md) for the latest compatibility matrix.

### Console SDK Version Mapping
```json
{
  "devDependencies": {
    "@openshift-console/dynamic-plugin-sdk": "4.21-latest",
    "@openshift-console/dynamic-plugin-sdk-webpack": "4.21-latest"
  }
}
```

**SDK Version Scheme:**
- SDK packages follow semver where major/minor version indicates supported OpenShift Console version
- Example: `4.21.x` supports OpenShift Console 4.21.x
- Prerelease versions: `"4.19.0-prerelease.1"` (development builds)
- Full releases: `"4.19.0"` (published after Console GA)

### PatternFly Version Compatibility Matrix

| OpenShift Console Version | Supported PatternFly Versions | Recommended |
|---------------------------|-------------------------------|-------------|
| 4.22.x | PatternFly 6.x | ✅ PF6 |
| 4.19.x - 4.22.x | PatternFly 6.x, 5.x | ✅ PF6 |
| 4.15.x - 4.18.x | PatternFly 5.x, 4.x | ✅ PF5 |
| 4.12.x - 4.14.x | PatternFly 4.x | ⚠️ PF4 (legacy) |

```json
{
  "devDependencies": {
    "@patternfly/react-core": "^6.0.0",
    "@patternfly/react-icons": "^6.0.0", 
    "@patternfly/react-table": "^6.0.0"
  }
}
```

### Shared Libraries Provided by Console

The OpenShift Console provides these shared modules to avoid duplication:

**Core Libraries:**
- `@openshift/dynamic-plugin-sdk`
- `@openshift-console/dynamic-plugin-sdk`
- `react` (version managed by console)
- `react-dom`
- `react-redux`
- `redux`

**UI Libraries:**
- `@patternfly/react-core`
- `@patternfly/react-icons`
- `@patternfly/react-table`

**Additional Libraries:**
- Various utility libraries (check the [official SDK documentation](https://github.com/openshift/console/blob/main/frontend/packages/console-dynamic-plugin-sdk/README.md) for current list)

## Version Selection Best Practices

1. **Target Specific Console Version**: Use exact SDK version matching your target OpenShift release
```json
{
  "@openshift-console/dynamic-plugin-sdk": "4.21.0" // Exact version
}
```

2. **Use Version Ranges for Broader Compatibility**: 
```json
{
  "@openshift-console/dynamic-plugin-sdk": "^4.21.0" // Compatible versions
}
```

3. **Pin PatternFly Major Version**:
```json
{
  "@patternfly/react-core": "^6.0.0" // Pin to PF6 for console 4.22+
}
```

4. **Check Compatibility Before Upgrading**:
```bash
# Always check latest compatibility matrix
curl -s https://raw.githubusercontent.com/openshift/console/main/frontend/packages/console-dynamic-plugin-sdk/README.md | grep -A 20 "Version compatibility"
```

## TypeScript Configuration

### Basic TypeScript Setup
```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "module": "esnext",
    "moduleResolution": "node",
    "target": "es2021",
    "sourceMap": true,
    "jsx": "react-jsx",
    "allowJs": true,
    "strict": false,
    "noUnusedLocals": true,
    "allowSyntheticDefaultImports": true,
    "esModuleInterop": true,
    "lib": ["ES2021", "DOM", "DOM.Iterable"]
  },
  "include": ["src"],
  "exclude": ["node_modules"]
}
```

### Strict TypeScript Setup (Recommended)
```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "module": "esnext",
    "moduleResolution": "node",
    "target": "es2021",
    "sourceMap": true,
    "jsx": "react-jsx",
    "allowJs": false,
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "allowSyntheticDefaultImports": true,
    "esModuleInterop": true,
    "lib": ["ES2021", "DOM", "DOM.Iterable"]
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist"]
}
```

## Version Troubleshooting

### Common Version-Related Issues
- **Runtime errors**: Version mismatch between plugin and console shared modules
- **Styling issues**: PatternFly version incompatibility  
- **Build failures**: SDK version doesn't support target OpenShift version
- **Type errors**: TypeScript definitions mismatch

### Resolution Steps
1. Verify OpenShift cluster version: `oc version`
2. Check console version in cluster
3. Update SDK versions to match console version
4. Update PatternFly to compatible version
5. Clear node_modules and reinstall: `rm -rf node_modules && npm install`

## Related Skills

- [openshift-console-plugin-extensions](../openshift-console-plugin-extensions/SKILL.md) - Console extension points and integration
- [openshift-console-plugin-components](../openshift-console-plugin-components/SKILL.md) - React component development patterns  
- [openshift-console-plugin-development](../openshift-console-plugin-development/SKILL.md) - Development workflow and testing
- [openshift-console-plugin-deployment](../openshift-console-plugin-deployment/SKILL.md) - Build and deployment strategies

## Quick Setup Checklist

- [ ] Create project structure with essential directories
- [ ] Configure package.json with plugin metadata
- [ ] Set up TypeScript configuration
- [ ] Install compatible SDK and PatternFly versions
- [ ] Verify version compatibility with target OpenShift release
- [ ] Configure webpack for module federation
- [ ] Set up development scripts
- [ ] Initialize i18n support
- [ ] Configure linting and testing