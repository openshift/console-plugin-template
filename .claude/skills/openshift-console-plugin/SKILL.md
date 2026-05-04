---
name: openshift-console-plugin
description: Comprehensive guide for developing OpenShift Console dynamic plugins - overview and navigation to specialized skills
---

# OpenShift Console Plugin Development

This is the main skill for OpenShift Console plugin development. For comprehensive guidance, this skill has been organized into specialized skills covering different aspects of plugin development. Use this overview to navigate to the specific area you need.

## Skill Overview

The OpenShift Console plugin development workflow is broken down into focused, specialized skills:

### 🏗️ [Project Setup](../openshift-console-plugin-setup/SKILL.md)
**Essential first step** - Project initialization, dependencies, and version compatibility

**When to use:** Starting a new plugin project, updating dependencies, or troubleshooting version compatibility issues.

**Key topics:**
- Project structure and essential files
- OpenShift version compatibility matrix
- PatternFly version mapping
- TypeScript configuration
- Package.json plugin metadata

---

### 🧩 [Console Extensions](../openshift-console-plugin-extensions/SKILL.md)
**Core integration** - Console extension points, navigation, routes, and integration patterns

**When to use:** Adding navigation items, creating custom pages, adding tabs to existing resources, or integrating with console features.

**Key topics:**
- Navigation extensions and sections
- Page routes and resource pages
- Tab extensions and action providers
- Feature flags and conditional extensions
- Extension best practices

---

### ⚛️ [Component Development](../openshift-console-plugin-components/SKILL.md)
**UI building blocks** - React component patterns and development best practices

**When to use:** Creating React components, building user interfaces, implementing component patterns, or optimizing component performance.

**Key topics:**
- Component development patterns
- Resource list and detail components
- Modal and form patterns
- Error handling and loading states
- TypeScript interfaces and accessibility

---

### 📊 [Data Management](../openshift-console-plugin-data/SKILL.md)
**K8s integration** - Data fetching, SDK helpers, and state management

**When to use:** Working with Kubernetes resources, implementing data fetching, managing application state, or optimizing API calls.

**Key topics:**
- K8s SDK helpers (useK8sWatchResource, k8sGet)
- API group/version configuration
- Resource mutations (create, update, delete)
- Custom hooks and state management
- Error handling and performance optimization

---

### 🎨 [UI Design & Styling](../openshift-console-plugin-styling/SKILL.md)
**Visual consistency** - PatternFly usage, CSS best practices, and theming

**When to use:** Styling components, ensuring design consistency, implementing responsive design, or troubleshooting theme compatibility.

**Key topics:**
- PatternFly component usage
- CSS best practices and avoiding inline styles
- Component styling approaches
- Theme compatibility and responsive design
- Performance optimization for styles

---

### 🔄 [Development Workflow](../openshift-console-plugin-development/SKILL.md)
**Development process** - Local development, testing, linting, and debugging

**When to use:** Setting up local development, running tests, debugging issues, or establishing development workflows.

**Key topics:**
- Local development setup (dev server + console container)
- Testing strategies (Jest, Cypress)
- Code quality and linting
- Debugging techniques
- Pre-commit workflows and best practices

---

### 🌍 [Internationalization](../openshift-console-plugin-i18n/SKILL.md)
**Multi-language support** - Translation setup, namespace conventions, and localization

**When to use:** Adding multi-language support, setting up translations, or implementing i18n in components and extensions.

**Key topics:**
- i18n namespace conventions
- Translation file structure
- Using translations in React components
- Console extension i18n
- Translation workflow and testing

---

### 🚀 [Deployment](../openshift-console-plugin-deployment/SKILL.md)
**Production delivery** - Build, containerization, Helm charts, and CI/CD

**When to use:** Building production releases, creating container images, setting up deployments, or configuring CI/CD pipelines.

**Key topics:**
- Webpack production builds
- Containerization with Docker/Podman
- Helm chart development
- CI/CD integration (GitHub Actions)
- Production deployment strategies

---

### 🏆 [Advanced Patterns](../openshift-console-plugin-advanced/SKILL.md)
**Expert techniques** - Performance optimization, security, and complex patterns

**When to use:** Optimizing performance, implementing security best practices, handling complex state management, or building advanced plugin features.

**Key topics:**
- Code splitting and lazy loading
- Security best practices and CSP
- Advanced state management patterns
- Error handling and resilience
- Performance optimization techniques

---

## Quick Start Guide

### For New Plugin Development:
1. **Start with [Setup](../openshift-console-plugin-setup/SKILL.md)** - Initialize project and configure dependencies
2. **Define [Extensions](../openshift-console-plugin-extensions/SKILL.md)** - Plan your console integration points
3. **Build [Components](../openshift-console-plugin-components/SKILL.md)** - Create your React components
4. **Implement [Data](../openshift-console-plugin-data/SKILL.md)** - Add K8s resource integration
5. **Apply [Styling](../openshift-console-plugin-styling/SKILL.md)** - Use PatternFly for consistent UI
6. **Setup [Development](../openshift-console-plugin-development/SKILL.md)** - Configure testing and workflows

### For Existing Plugin Enhancement:
- **Adding features** → [Extensions](../openshift-console-plugin-extensions/SKILL.md) + [Components](../openshift-console-plugin-components/SKILL.md)
- **Performance issues** → [Advanced Patterns](../openshift-console-plugin-advanced/SKILL.md)
- **Multi-language** → [Internationalization](../openshift-console-plugin-i18n/SKILL.md)
- **Production deployment** → [Deployment](../openshift-console-plugin-deployment/SKILL.md)

### For Troubleshooting:
- **Plugin not loading** → [Development](../openshift-console-plugin-development/SKILL.md)
- **Version conflicts** → [Setup](../openshift-console-plugin-setup/SKILL.md)
- **UI/styling issues** → [Styling](../openshift-console-plugin-styling/SKILL.md)
- **Data/API problems** → [Data Management](../openshift-console-plugin-data/SKILL.md)

## Development Principles

### Core Principles Across All Skills:

1. **Use SDK Helpers**: Always use OpenShift Console SDK helpers for K8s operations
2. **PatternFly First**: Prefer PatternFly components over custom implementations
3. **TypeScript**: Use TypeScript for type safety and better development experience
4. **Accessibility**: Follow WCAG guidelines and use proper ARIA attributes
5. **Internationalization**: Support multiple languages from the start
6. **Testing**: Write tests for components, hooks, and critical user flows
7. **Security**: Validate inputs, sanitize outputs, and follow security best practices
8. **Performance**: Optimize for bundle size and runtime performance

### Quality Standards:

- ✅ **Linting**: Run `yarn lint` before every commit
- ✅ **Testing**: Maintain comprehensive test coverage
- ✅ **Type Safety**: Use TypeScript interfaces for all data structures
- ✅ **Accessibility**: Test with screen readers and keyboard navigation
- ✅ **Documentation**: Keep documentation updated with code changes
- ✅ **Consistency**: Follow established patterns across the codebase

## Common Tasks Quick Reference

| Task | Primary Skill | Supporting Skills |
|------|---------------|------------------|
| Project initialization | [Setup](../openshift-console-plugin-setup/SKILL.md) | [Development](../openshift-console-plugin-development/SKILL.md) |
| Add navigation menu | [Extensions](../openshift-console-plugin-extensions/SKILL.md) | [i18n](../openshift-console-plugin-i18n/SKILL.md) |
| Create custom page | [Components](../openshift-console-plugin-components/SKILL.md) | [Extensions](../openshift-console-plugin-extensions/SKILL.md) |
| Fetch K8s resources | [Data Management](../openshift-console-plugin-data/SKILL.md) | [Components](../openshift-console-plugin-components/SKILL.md) |
| Style components | [Styling](../openshift-console-plugin-styling/SKILL.md) | [Components](../openshift-console-plugin-components/SKILL.md) |
| Add translations | [i18n](../openshift-console-plugin-i18n/SKILL.md) | [Components](../openshift-console-plugin-components/SKILL.md) |
| Deploy to production | [Deployment](../openshift-console-plugin-deployment/SKILL.md) | [Advanced](../openshift-console-plugin-advanced/SKILL.md) |
| Optimize performance | [Advanced](../openshift-console-plugin-advanced/SKILL.md) | [Styling](../openshift-console-plugin-styling/SKILL.md) |

## Getting Help

Each specialized skill contains:
- **Comprehensive examples** with copy-paste code
- **Best practices** and common patterns
- **Troubleshooting guides** for common issues
- **Cross-references** to related skills
- **Checklists** to ensure completeness

Start with the skill most relevant to your current task, and follow the cross-references to related skills as needed.