---
name: openshift-console-plugin-i18n
description: Internationalization and localization for OpenShift Console plugins
---

# OpenShift Console Plugin Internationalization (i18n)

This skill covers internationalization and localization for OpenShift Console plugins, including translation setup, namespace conventions, and best practices for multi-language support.

## i18n Overview

Internationalization enables your console plugin to support multiple languages and regions. The OpenShift Console uses react-i18next for translation management, and plugins must follow specific namespace conventions.

### Core Requirements
- **Namespace Convention**: `plugin__<plugin-name>` (matches ConsolePlugin resource name)
- **Translation Files**: Located in `/locales` directory
- **Default Language**: English (en) is required
- **Key Format**: Use descriptive, hierarchical keys

## Namespace Convention

**⚠️ CRITICAL: Namespace must match your ConsolePlugin resource name**

```typescript
// If your ConsolePlugin resource is named "my-console-plugin"
const PLUGIN_NAMESPACE = 'plugin__my-console-plugin';

// Use this namespace in all translation calls
const { t } = useTranslation('plugin__my-console-plugin');
```

### ConsolePlugin Resource Name Matching
```yaml
# In your Helm chart or YAML manifest
apiVersion: console.openshift.io/v1
kind: ConsolePlugin
metadata:
  name: my-console-plugin  # This determines your i18n namespace
spec:
  displayName: "My Console Plugin"
```

```typescript
// i18n namespace MUST match the resource name above
const namespace = 'plugin__my-console-plugin';
```

## Translation Setup

### Directory Structure
```
my-console-plugin/
├── locales/
│   ├── en/
│   │   └── plugin__my-console-plugin.json
│   ├── es/
│   │   └── plugin__my-console-plugin.json
│   ├── fr/
│   │   └── plugin__my-console-plugin.json
│   └── zh/
│       └── plugin__my-console-plugin.json
├── src/
│   └── components/
└── package.json
```

### English Translation File (Required)
```json
{
  "My Plugin": "My Plugin",
  "Dashboard": "Dashboard",
  "Resources": "Resources",
  "Create Resource": "Create Resource",
  "Edit Resource": "Edit Resource",
  "Delete Resource": "Delete Resource",
  "Name": "Name",
  "Namespace": "Namespace", 
  "Status": "Status",
  "Created": "Created",
  "Actions": "Actions",
  "Loading": "Loading...",
  "No resources found": "No resources found",
  "Error loading resources": "Error loading resources",
  "Resource created successfully": "Resource created successfully",
  "Failed to create resource": "Failed to create resource",
  "Are you sure you want to delete {{name}}?": "Are you sure you want to delete {{name}}?",
  "This action cannot be undone": "This action cannot be undone",
  "resource": "resource",
  "resources": "resources",
  "{{count}} resource": "{{count}} resource",
  "{{count}} resource_plural": "{{count}} resources",
  "Welcome": "Welcome",
  "Getting Started": "Getting Started",
  "Documentation": "Documentation",
  "Support": "Support",
  "Settings": "Settings",
  "Configuration": "Configuration",
  "Advanced": "Advanced",
  "Overview": "Overview",
  "Details": "Details",
  "YAML": "YAML",
  "Events": "Events",
  "Logs": "Logs",
  "Metrics": "Metrics",
  "Ready": "Ready",
  "Pending": "Pending",
  "Error": "Error",
  "Unknown": "Unknown",
  "Healthy": "Healthy",
  "Unhealthy": "Unhealthy",
  "Running": "Running",
  "Stopped": "Stopped",
  "Success": "Success",
  "Warning": "Warning",
  "Info": "Information"
}
```

## Using Translations in Components

### Basic Translation Hook
```typescript
import React from 'react';
import { useTranslation } from 'react-i18next';
import { Page, PageSection, Title } from '@patternfly/react-core';

const MyPage: React.FC = () => {
  const { t } = useTranslation('plugin__my-console-plugin');

  return (
    <Page>
      <PageSection variant="light">
        <Title headingLevel="h1">{t('My Plugin')}</Title>
      </PageSection>
      <PageSection>
        <p>{t('Welcome to the plugin dashboard')}</p>
      </PageSection>
    </Page>
  );
};
```

### Translations with Variables
```typescript
const ResourceCard: React.FC<{ resource: MyResource }> = ({ resource }) => {
  const { t } = useTranslation('plugin__my-console-plugin');
  const name = resource.metadata?.name;
  
  return (
    <Card>
      <CardTitle>{t('Resource Details for {{name}}', { name })}</CardTitle>
      <CardBody>
        <p>{t('Status: {{status}}', { status: resource.status?.phase })}</p>
        <p>{t('Created: {{date}}', { 
          date: new Date(resource.metadata?.creationTimestamp).toLocaleDateString() 
        })}</p>
      </CardBody>
    </Card>
  );
};
```

### Pluralization
```typescript
const ResourceList: React.FC<{ resources: MyResource[] }> = ({ resources }) => {
  const { t } = useTranslation('plugin__my-console-plugin');
  
  return (
    <div>
      <Title headingLevel="h2">
        {t('{{count}} resource', { count: resources.length })}
      </Title>
      {resources.length === 0 && (
        <EmptyState>
          <Title headingLevel="h4">{t('No resources found')}</Title>
        </EmptyState>
      )}
    </div>
  );
};
```

### Complex Formatting
```typescript
const DeleteConfirmation: React.FC<{ resourceName: string }> = ({ resourceName }) => {
  const { t } = useTranslation('plugin__my-console-plugin');
  
  return (
    <Modal title={t('Delete Resource')}>
      <Stack hasGutter>
        <StackItem>
          <p>{t('Are you sure you want to delete {{name}}?', { name: resourceName })}</p>
        </StackItem>
        <StackItem>
          <Alert variant="warning" title={t('This action cannot be undone')} />
        </StackItem>
      </Stack>
    </Modal>
  );
};
```

## Console Extensions i18n

### Navigation Extensions
```json
{
  "type": "console.navigation/section",
  "properties": {
    "id": "my-plugin-section",
    "perspective": "admin",
    "name": "%plugin__my-console-plugin~My Plugin%"
  }
}
```

### Page Routes with i18n
```json
{
  "type": "console.navigation/href",
  "properties": {
    "id": "my-plugin-dashboard",
    "name": "%plugin__my-console-plugin~Dashboard%",
    "href": "/my-plugin/dashboard",
    "section": "my-plugin-section"
  }
}
```

### Tab Extensions
```json
{
  "type": "console.tab",
  "properties": {
    "model": {
      "group": "apps",
      "version": "v1",
      "kind": "Deployment"
    },
    "component": { "$codeRef": "MyResourceTab" },
    "name": "%plugin__my-console-plugin~Monitoring%"
  }
}
```

## Advanced Translation Patterns

### Conditional Translations
```typescript
const StatusBadge: React.FC<{ status: string; isError: boolean }> = ({ status, isError }) => {
  const { t } = useTranslation('plugin__my-console-plugin');
  
  const getStatusText = () => {
    if (isError) return t('Error');
    
    switch (status) {
      case 'Ready': return t('Ready');
      case 'Pending': return t('Pending');
      case 'Running': return t('Running');
      default: return t('Unknown');
    }
  };
  
  return (
    <Label color={isError ? 'red' : 'green'}>
      {getStatusText()}
    </Label>
  );
};
```

### Date and Time Formatting
```typescript
const ResourceTimestamp: React.FC<{ timestamp: string }> = ({ timestamp }) => {
  const { t, i18n } = useTranslation('plugin__my-console-plugin');
  
  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat(i18n.language, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    }).format(date);
  };
  
  return (
    <span title={t('Created at {{time}}', { time: formatDate(timestamp) })}>
      {formatDate(timestamp)}
    </span>
  );
};
```

### Number Formatting
```typescript
const ResourceMetrics: React.FC<{ cpuUsage: number; memoryUsage: number }> = ({ 
  cpuUsage, 
  memoryUsage 
}) => {
  const { t, i18n } = useTranslation('plugin__my-console-plugin');
  
  const formatNumber = (value: number) => {
    return new Intl.NumberFormat(i18n.language, {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }).format(value);
  };
  
  return (
    <DescriptionList>
      <DescriptionListGroup>
        <DescriptionListTerm>{t('CPU Usage')}</DescriptionListTerm>
        <DescriptionListDescription>
          {t('{{value}}%', { value: formatNumber(cpuUsage) })}
        </DescriptionListDescription>
      </DescriptionListGroup>
      <DescriptionListGroup>
        <DescriptionListTerm>{t('Memory Usage')}</DescriptionListTerm>
        <DescriptionListDescription>
          {t('{{value}} MB', { value: formatNumber(memoryUsage) })}
        </DescriptionListDescription>
      </DescriptionListGroup>
    </DescriptionList>
  );
};
```

## Translation Workflow

### Adding New Translations
```bash
# 1. Add new keys to English translation file
# locales/en/plugin__my-console-plugin.json

# 2. Use the translation in your component
const { t } = useTranslation('plugin__my-console-plugin');
const text = t('New feature description');

# 3. Update all translation files
npm run i18n

# 4. Send translation files to translators
# 5. Update translation files with translated content
```

### Translation Build Process
```json
{
  "scripts": {
    "i18n": "i18next-scanner --config i18next-scanner.config.js",
    "i18n:extract": "i18next-scanner",
    "i18n:build": "node scripts/build-i18n.js"
  }
}
```

### i18n Scanner Configuration
```javascript
// i18next-scanner.config.js
module.exports = {
  input: [
    'src/**/*.{js,jsx,ts,tsx}',
    'console-extensions.json'
  ],
  output: './locales',
  options: {
    debug: false,
    func: {
      list: ['t', 'i18next.t', 'i18n.t'],
      extensions: ['.js', '.jsx', '.ts', '.tsx']
    },
    trans: {
      component: 'Trans',
      i18nKey: 'i18nKey',
      defaultsKey: 'defaults',
      extensions: ['.js', '.jsx', '.ts', '.tsx']
    },
    lngs: ['en'],
    ns: [`plugin__${require('./package.json').consolePlugin.name}`],
    defaultLng: 'en',
    defaultNs: `plugin__${require('./package.json').consolePlugin.name}`,
    resource: {
      loadPath: '{{lng}}/{{ns}}.json',
      savePath: '{{lng}}/{{ns}}.json',
      jsonIndent: 2
    },
    nsSeparator: '~',
    keySeparator: false
  }
};
```

## Multi-language Support

### Spanish Translation Example
```json
{
  "My Plugin": "Mi Plugin",
  "Dashboard": "Panel de Control",
  "Resources": "Recursos", 
  "Create Resource": "Crear Recurso",
  "Edit Resource": "Editar Recurso",
  "Delete Resource": "Eliminar Recurso",
  "Name": "Nombre",
  "Namespace": "Espacio de Nombres",
  "Status": "Estado",
  "Created": "Creado",
  "Actions": "Acciones",
  "Loading": "Cargando...",
  "No resources found": "No se encontraron recursos",
  "Error loading resources": "Error al cargar recursos",
  "Resource created successfully": "Recurso creado exitosamente",
  "Failed to create resource": "Error al crear recurso",
  "Are you sure you want to delete {{name}}?": "¿Está seguro de que desea eliminar {{name}}?",
  "This action cannot be undone": "Esta acción no se puede deshacer",
  "{{count}} resource": "{{count}} recurso",
  "{{count}} resource_plural": "{{count}} recursos"
}
```

### French Translation Example
```json
{
  "My Plugin": "Mon Plugin",
  "Dashboard": "Tableau de Bord",
  "Resources": "Ressources",
  "Create Resource": "Créer une Ressource",
  "Edit Resource": "Modifier la Ressource",
  "Delete Resource": "Supprimer la Ressource",
  "Name": "Nom",
  "Namespace": "Espace de Noms",
  "Status": "État",
  "Created": "Créé",
  "Actions": "Actions",
  "Loading": "Chargement...",
  "No resources found": "Aucune ressource trouvée",
  "Error loading resources": "Erreur lors du chargement des ressources",
  "{{count}} resource": "{{count}} ressource",
  "{{count}} resource_plural": "{{count}} ressources"
}
```

## Testing Translations

### Translation Testing
```typescript
// src/utils/i18n-test.ts
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

// Test translations
const testResources = {
  en: {
    'plugin__my-console-plugin': {
      'My Plugin': 'My Plugin',
      'Dashboard': 'Dashboard',
      'Loading': 'Loading...',
      'No resources found': 'No resources found'
    }
  }
};

i18n
  .use(initReactI18next)
  .init({
    lng: 'en',
    fallbackLng: 'en',
    debug: false,
    resources: testResources,
    ns: ['plugin__my-console-plugin'],
    defaultNS: 'plugin__my-console-plugin'
  });

export default i18n;
```

### Component Testing with i18n
```typescript
// src/components/__tests__/MyPage.test.tsx
import React from 'react';
import { render, screen } from '@testing-library/react';
import { I18nextProvider } from 'react-i18next';
import i18n from '../../utils/i18n-test';
import MyPage from '../MyPage';

describe('MyPage with i18n', () => {
  const renderWithI18n = (component: React.ReactElement) => {
    return render(
      <I18nextProvider i18n={i18n}>
        {component}
      </I18nextProvider>
    );
  };

  it('renders translated content', () => {
    renderWithI18n(<MyPage />);
    expect(screen.getByText('My Plugin')).toBeInTheDocument();
    expect(screen.getByText('Dashboard')).toBeInTheDocument();
  });
});
```

## Best Practices

### Translation Key Naming
```json
{
  "page.dashboard.title": "Dashboard",
  "page.dashboard.description": "View system overview",
  "action.create": "Create", 
  "action.edit": "Edit",
  "action.delete": "Delete",
  "status.ready": "Ready",
  "status.pending": "Pending",
  "status.error": "Error",
  "message.success.create": "Resource created successfully",
  "message.error.create": "Failed to create resource",
  "modal.delete.title": "Delete Resource",
  "modal.delete.confirm": "Are you sure you want to delete {{name}}?"
}
```

### Context-Aware Translations
```typescript
const ActionButton: React.FC<{ action: 'create' | 'edit' | 'delete'; resource: string }> = ({ 
  action, 
  resource 
}) => {
  const { t } = useTranslation('plugin__my-console-plugin');
  
  const getActionText = () => {
    switch (action) {
      case 'create': return t('action.create.resource', { resource });
      case 'edit': return t('action.edit.resource', { resource });
      case 'delete': return t('action.delete.resource', { resource });
    }
  };
  
  return <Button>{getActionText()}</Button>;
};
```

## Related Skills

- [openshift-console-plugin-extensions](../openshift-console-plugin-extensions/SKILL.md) - Using i18n in console extensions
- [openshift-console-plugin-components](../openshift-console-plugin-components/SKILL.md) - Component translation patterns
- [openshift-console-plugin-setup](../openshift-console-plugin-setup/SKILL.md) - Project setup with i18n
- [openshift-console-plugin-development](../openshift-console-plugin-development/SKILL.md) - Testing translations

## i18n Checklist

- [ ] Namespace matches ConsolePlugin resource name
- [ ] English translation file exists and is complete
- [ ] All user-facing strings use translation keys
- [ ] Console extensions use i18n format (%namespace~key%)
- [ ] Pluralization rules implemented for count-based content
- [ ] Date and number formatting uses locale-aware methods
- [ ] Translation extraction process configured
- [ ] Tests include i18n provider
- [ ] Variable interpolation used for dynamic content
- [ ] Context-aware translations for ambiguous terms
- [ ] All supported languages have translation files
- [ ] Translation build process integrated into CI/CD