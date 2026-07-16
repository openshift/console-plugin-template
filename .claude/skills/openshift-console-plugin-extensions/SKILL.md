---
name: openshift-console-plugin-extensions
description: Console extension points, navigation, routes, and integration patterns for OpenShift Console plugins
---

# OpenShift Console Plugin Extensions

This skill covers console extension points and integration patterns for extending the OpenShift Console with custom functionality. Learn how to add navigation, routes, tabs, and actions to the console.

## Console Extensions Overview

Console extensions are declared in `console-extensions.json` and define how your plugin integrates with the OpenShift Console. Each extension must have a corresponding module in your `package.json` `exposedModules` section.

### Critical Requirements
- **Extension-Module Mapping**: Every `$codeRef` in extensions must match an entry in `exposedModules`
- **Type Safety**: Use proper TypeScript types for all extension properties
- **i18n Support**: Use translation keys for user-facing strings

## Navigation Extensions

### Navigation Sections
Create logical groupings for your plugin's navigation items:

```json
{
  "type": "console.navigation/section",
  "properties": {
    "id": "my-plugin-section",
    "perspective": "admin",
    "name": "%plugin__my-console-plugin~My Section%"
  }
}
```

### Navigation Links
Add navigation items that link to your plugin pages:

```json
{
  "type": "console.navigation/href",
  "properties": {
    "id": "my-plugin-nav",
    "name": "%plugin__my-console-plugin~My Feature%",
    "href": "/my-feature",
    "perspective": "admin",
    "section": "my-plugin-section",
    "insertAfter": "workloads"
  }
}
```

### Navigation with Resources
Link navigation to specific Kubernetes resources:

```json
{
  "type": "console.navigation/resource-ns",
  "properties": {
    "id": "my-resources-nav",
    "name": "%plugin__my-console-plugin~My Resources%",
    "section": "my-plugin-section",
    "model": {
      "group": "my-group.io",
      "version": "v1",
      "kind": "MyResource"
    }
  }
}
```

## Page Routes

### Basic Page Routes
Define routes for your plugin pages:

```json
{
  "type": "console.page/route",
  "properties": {
    "path": "/my-feature",
    "component": { "$codeRef": "MyPage" }
  }
}
```

### Parameterized Routes
Create routes with URL parameters:

```json
{
  "type": "console.page/route", 
  "properties": {
    "path": "/my-feature/:id",
    "component": { "$codeRef": "MyDetailsPage" }
  }
}
```

### Namespace-scoped Routes
Routes that work within namespace contexts:

```json
{
  "type": "console.page/route",
  "properties": {
    "path": "/ns/:ns/my-feature",
    "component": { "$codeRef": "MyNamespacedPage" }
  }
}
```

## Resource Pages

### Resource List Pages
Override or create list pages for Kubernetes resources:

```json
{
  "type": "console.page/resource/list",
  "properties": {
    "model": {
      "group": "my-group.io",
      "version": "v1",
      "kind": "MyResource"
    },
    "component": { "$codeRef": "MyResourceList" }
  }
}
```

### Resource Detail Pages
Create detailed views for individual resources:

```json
{
  "type": "console.page/resource/details",
  "properties": {
    "model": {
      "group": "my-group.io", 
      "version": "v1",
      "kind": "MyResource"
    },
    "component": { "$codeRef": "MyResourceDetails" }
  }
}
```

## Tab Extensions

### Resource Detail Tabs
Add tabs to existing resource detail pages:

```json
{
  "type": "console.tab",
  "properties": {
    "model": {
      "group": "apps",
      "version": "v1", 
      "kind": "Deployment"
    },
    "component": { "$codeRef": "MyResourceMonitoringTab" },
    "name": "%plugin__my-console-plugin~Monitoring%"
  }
}
```

### Conditional Tabs
Show tabs only when certain conditions are met:

```json
{
  "type": "console.tab",
  "properties": {
    "model": {
      "group": "apps",
      "version": "v1",
      "kind": "Deployment"
    },
    "component": { "$codeRef": "MyConditionalTab" },
    "name": "%plugin__my-console-plugin~Advanced%"
  },
  "flags": {
    "required": ["MY_FEATURE_FLAG"]
  }
}
```

## Action Extensions

### Resource Actions
Add actions to resource pages (kebab menus, buttons):

```json
{
  "type": "console.action/resource-provider",
  "properties": {
    "model": {
      "group": "my-group.io",
      "version": "v1", 
      "kind": "MyResource"
    },
    "provider": { "$codeRef": "myResourceActions" }
  }
}
```

### Global Actions
Add actions to global areas like the utility menu:

```json
{
  "type": "console.action/provider",
  "properties": {
    "contextId": "topnav-utility-menu",
    "provider": { "$codeRef": "myGlobalActions" }
  }
}
```

## Feature Flags

### Declaring Feature Flags
Enable conditional functionality:

```json
{
  "type": "console.flag",
  "properties": {
    "flag": "MY_FEATURE_FLAG",
    "handler": { "$codeRef": "myFeatureFlag" }
  }
}
```

### Using Flags in Extensions
Control extension visibility with flags:

```json
{
  "type": "console.page/route",
  "properties": {
    "path": "/experimental-feature",
    "component": { "$codeRef": "ExperimentalPage" }
  },
  "flags": {
    "required": ["EXPERIMENTAL_FEATURES"]
  }
}
```

## Dashboard Extensions

### Dashboard Cards
Add cards to overview dashboards:

```json
{
  "type": "console.dashboards/overview/health/url",
  "properties": {
    "title": "%plugin__my-console-plugin~My Service Health%",
    "url": "/api/my-plugin/health",
    "healthHandler": { "$codeRef": "myHealthHandler" }
  }
}
```

### Activity Cards
Show activities in the Home page:

```json
{
  "type": "console.dashboards/overview/activity/resource",
  "properties": {
    "k8sResource": {
      "prop": "myResources",
      "isList": true,
      "kind": "MyResource"
    },
    "component": { "$codeRef": "MyActivityCard" }
  }
}
```

## Model Registration

### Custom Resource Models
Register your custom resources with the console:

```json
{
  "type": "console.model",
  "properties": {
    "models": [
      {
        "group": "my-group.io",
        "version": "v1",
        "kind": "MyResource",
        "plural": "myresources",
        "namespaced": true,
        "crd": true
      }
    ]
  }
}
```

## YAML Template Extensions

### YAML Templates
Provide templates for creating resources:

```json
{
  "type": "console.yaml-template",
  "properties": {
    "model": {
      "group": "my-group.io",
      "version": "v1",
      "kind": "MyResource"
    },
    "template": { "$codeRef": "myResourceTemplate" },
    "name": "My Resource Template"
  }
}
```

## Extension Best Practices

### 1. Consistent Naming
```json
{
  "id": "my-plugin-feature-name",  // Use plugin prefix
  "name": "%plugin__my-console-plugin~Feature Name%"  // Always use i18n
}
```

### 2. Proper Model References
```json
{
  "model": {
    "group": "apps",      // Separate group property
    "version": "v1",      // Separate version property
    "kind": "Deployment"  // Exact kind name
  }
}
```

### 3. Code Reference Mapping
```json
// In console-extensions.json
"component": { "$codeRef": "MyPage" }

// In package.json
"exposedModules": {
  "MyPage": "./components/MyPage"  // Must match exactly
}
```

### 4. Perspective Targeting
```json
{
  "perspective": "admin",     // Target specific perspective
  "perspective": "dev",       // Or developer perspective  
  "perspective": "*"          // Or all perspectives
}
```

## Common Extension Patterns

### Multi-tab Resource Page
```json
[
  {
    "type": "console.page/resource/details",
    "properties": {
      "model": { "group": "my-group.io", "version": "v1", "kind": "MyResource" },
      "component": { "$codeRef": "MyResourceDetails" }
    }
  },
  {
    "type": "console.tab",
    "properties": {
      "model": { "group": "my-group.io", "version": "v1", "kind": "MyResource" },
      "component": { "$codeRef": "MyResourceEventsTab" },
      "name": "%plugin__my-console-plugin~Events%"
    }
  },
  {
    "type": "console.tab", 
    "properties": {
      "model": { "group": "my-group.io", "version": "v1", "kind": "MyResource" },
      "component": { "$codeRef": "MyResourceLogsTab" },
      "name": "%plugin__my-console-plugin~Logs%"
    }
  }
]
```

### Navigation with Sub-items
```json
[
  {
    "type": "console.navigation/section",
    "properties": {
      "id": "my-plugin-section",
      "perspective": "admin",
      "name": "%plugin__my-console-plugin~My Plugin%"
    }
  },
  {
    "type": "console.navigation/href",
    "properties": {
      "id": "my-plugin-overview",
      "name": "%plugin__my-console-plugin~Overview%",
      "href": "/my-plugin",
      "section": "my-plugin-section"
    }
  },
  {
    "type": "console.navigation/resource-ns",
    "properties": {
      "id": "my-resources",
      "section": "my-plugin-section",
      "model": { "group": "my-group.io", "version": "v1", "kind": "MyResource" }
    }
  }
]
```

## Related Skills

- [openshift-console-plugin-setup](../openshift-console-plugin-setup/SKILL.md) - Project setup and dependencies
- [openshift-console-plugin-components](../openshift-console-plugin-components/SKILL.md) - React component development
- [openshift-console-plugin-i18n](../openshift-console-plugin-i18n/SKILL.md) - Internationalization for extensions
- [openshift-console-plugin-development](../openshift-console-plugin-development/SKILL.md) - Development and testing workflow

## Extension Reference

### Most Common Extension Types
- `console.navigation/section` - Navigation sections
- `console.navigation/href` - Navigation links  
- `console.navigation/resource-ns` - Resource navigation
- `console.page/route` - Custom routes
- `console.page/resource/list` - Resource list pages
- `console.page/resource/details` - Resource detail pages
- `console.tab` - Resource detail tabs
- `console.action/resource-provider` - Resource actions
- `console.flag` - Feature flags
- `console.model` - Custom resource models