---
name: openshift-console-plugin
description: Expert guidance for developing OpenShift Console dynamic plugins using React, TypeScript, and PatternFly
---

# OpenShift Console Plugin Development Skill

This skill provides comprehensive guidance for developing dynamic plugins for the OpenShift Console. It covers the complete development lifecycle from project setup to deployment, incorporating best practices from production plugins like KubeVirt, Network Observability, Pipelines, and Networking.

## 1. Project Structure and Setup

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

## 2. Console Extensions and Integration Points

### Navigation Extensions
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

```json
{
  "type": "console.navigation/href",
  "properties": {
    "id": "my-plugin-nav",
    "name": "%plugin__my-console-plugin~My Feature%",
    "href": "/my-feature",
    "perspective": "admin",
    "section": "my-plugin-section"
  }
}
```

### Page Routes
```json
{
  "type": "console.page/route",
  "properties": {
    "path": "/my-feature",
    "component": { "$codeRef": "MyPage" }
  }
}
```

### Resource Pages and List Views
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

### Action Providers
```json
{
  "type": "console.action/provider",
  "properties": {
    "contextId": "resource-actions",
    "provider": { "$codeRef": "myResourceActions" }
  }
}
```


### Tab Extensions
```json
{
  "type": "console.tab",
  "properties": {
    "contextId": "resource-details",
    "name": "%plugin__my-console-plugin~Monitoring%",
    "href": "monitoring",
    "component": { "$codeRef": "MyResourceMonitoringTab" }
  }
}
```

## 3. Component Development Patterns

### Base Page Component
```typescript
import React from 'react';
import { useTranslation } from 'react-i18next';
import { 
  Page,
  PageSection,
  Title,
  Card,
  CardBody 
} from '@patternfly/react-core';

const MyPage: React.FC = () => {
  const { t } = useTranslation('plugin__my-console-plugin');
  
  return (
    <Page>
      <PageSection variant="light">
        <Title headingLevel="h1">
          {t('My Feature')}
        </Title>
      </PageSection>
      <PageSection>
        <Card>
          <CardBody>
            {/* Content */}
          </CardBody>
        </Card>
      </PageSection>
    </Page>
  );
};

export default MyPage;
```

### Resource List Component
```typescript
import React from 'react';
import { useTranslation } from 'react-i18next';
import {
  ListPage,
  TableColumn,
  useK8sWatchResource,
  VirtualizedTable,
  TableData,
  RowFunction
} from '@openshift-console/dynamic-plugin-sdk';
import { K8sResourceCommon } from '@openshift-console/dynamic-plugin-sdk';

interface MyResource extends K8sResourceCommon {
  spec: {
    // resource spec
  };
  status?: {
    // resource status
  };
}

const MyResourceList: React.FC = () => {
  const { t } = useTranslation('plugin__my-console-plugin');
  
  const [resources, loaded, loadError] = useK8sWatchResource<MyResource[]>({
    groupVersionKind: {
      group: 'my-group.io',
      version: 'v1',
      kind: 'MyResource',
    },
    isList: true,
  });

  const columns: TableColumn<MyResource>[] = [
    {
      title: t('Name'),
      id: 'name',
      transforms: [],
      props: { className: 'pf-m-width-20' },
    },
    {
      title: t('Namespace'),
      id: 'namespace', 
      transforms: [],
      props: { className: 'pf-m-width-20' },
    },
    {
      title: t('Status'),
      id: 'status',
      transforms: [],
      props: { className: 'pf-m-width-15' },
    },
  ];

  const Row: RowFunction<MyResource> = ({ obj, activeColumnIDs }) => (
    <>
      <TableData id="name" activeColumnIDs={activeColumnIDs}>
        <ResourceLink
          kind="MyResource"
          name={obj.metadata.name}
          namespace={obj.metadata.namespace}
        />
      </TableData>
      <TableData id="namespace" activeColumnIDs={activeColumnIDs}>
        {obj.metadata.namespace}
      </TableData>
      <TableData id="status" activeColumnIDs={activeColumnIDs}>
        {obj.status?.phase || 'Unknown'}
      </TableData>
    </>
  );

  return (
    <VirtualizedTable
      data={resources}
      unfilteredData={resources}
      loaded={loaded}
      loadError={loadError}
      columns={columns}
      Row={Row}
    />
  );
};

export default MyResourceList;
```

### Resource Details Component
```typescript
import React from 'react';
import { useParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import {
  DetailsPage,
  useK8sWatchResource,
  HorizontalNav,
  DetailsPageProps
} from '@openshift-console/dynamic-plugin-sdk';

const MyResourceDetailsPage: React.FC = () => {
  const { t } = useTranslation('plugin__my-console-plugin');
  const { ns, name } = useParams<{ ns: string; name: string }>();
  
  const [resource, loaded, loadError] = useK8sWatchResource<MyResource>({
    groupVersionKind: {
      group: 'my-group.io',
      version: 'v1',
      kind: 'MyResource',
    },
    name,
    namespace: ns,
  });

  const pages = [
    {
      href: '',
      name: t('Details'),
      component: MyResourceDetails,
    },
    {
      href: 'yaml',
      name: t('YAML'),
      component: YAMLEditorPage,
    },
    {
      href: 'events',
      name: t('Events'),
      component: EventsPage,
    },
  ];

  return (
    <DetailsPage
      {...props}
      pages={pages}
      kind="MyResource"
      name={name}
      namespace={ns}
      resource={resource}
      loaded={loaded}
      loadError={loadError}
    />
  );
};

export default MyResourceDetailsPage;
```

## 4. TypeScript Configuration and Patterns

### Strict TypeScript Setup
```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["dom", "dom.iterable", "es6"],
    "allowJs": false,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "module": "esnext",
    "moduleResolution": "node",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "noUnusedLocals": true,
    "noUnusedParameters": true
  },
  "include": [
    "src",
    "integration-tests"
  ]
}
```

### Type Definitions
```typescript
// src/types/index.ts
import { K8sResourceCommon } from '@openshift-console/dynamic-plugin-sdk';

export interface MyResourceSpec {
  replicas?: number;
  selector: {
    matchLabels: Record<string, string>;
  };
  template: {
    metadata?: {
      labels?: Record<string, string>;
    };
    spec: {
      containers: Container[];
    };
  };
}

export interface MyResourceStatus {
  phase: 'Pending' | 'Running' | 'Succeeded' | 'Failed';
  conditions?: Condition[];
  replicas?: number;
  readyReplicas?: number;
}

export interface MyResource extends K8sResourceCommon {
  spec: MyResourceSpec;
  status?: MyResourceStatus;
}

export interface Condition {
  type: string;
  status: 'True' | 'False' | 'Unknown';
  lastTransitionTime?: string;
  reason?: string;
  message?: string;
}
```

## 5. State Management and Data Fetching

### Using K8s SDK Helpers for Resource Operations

**⚠️ CRITICAL: Always use SDK helpers for Kubernetes resource operations**

**DO NOT construct API paths manually**. The console SDK provides helper functions that handle authentication, proper URL construction, error handling, and caching. Always use these instead of raw fetch calls or manual path construction.

#### Core SDK Helper Functions
```typescript
import { 
  useK8sWatchResource,
  k8sGet,
  k8sCreate, 
  k8sUpdate,
  k8sDelete,
  k8sList,
  consoleFetch
} from '@openshift-console/dynamic-plugin-sdk';
```

#### API Groups and Versions - Critical Configuration

**IMPORTANT**: API groups and versions must be specified as separate properties, not as combined strings.

```typescript
// ✅ CORRECT - Separate group and version properties
const resourceModel = {
  groupVersionKind: {
    group: 'apps',           // Separate property
    version: 'v1',           // Separate property  
    kind: 'Deployment'
  }
};

// ❌ WRONG - Do not combine group/version as single string
const badModel = {
  groupVersionKind: {
    group: 'apps/v1',        // WRONG - don't combine
    version: '',
    kind: 'Deployment'
  }
};
```

#### Mapping YAML apiVersion to SDK Properties
When you see a YAML resource with `apiVersion: "apps/v1"`, map it to SDK properties:

```yaml
# YAML resource shows:
apiVersion: apps/v1
kind: Deployment
```

```typescript
// Maps to SDK configuration:
const deploymentModel = {
  groupVersionKind: {
    group: 'apps',           // Everything before the '/'
    version: 'v1',           // Everything after the '/'  
    kind: 'Deployment'
  }
};

// Special case: Core resources (no group in YAML)
# YAML: apiVersion: v1
# Maps to: group: '', version: 'v1'
```

#### Watch Resources with useK8sWatchResource
```typescript
import { useK8sWatchResource } from '@openshift-console/dynamic-plugin-sdk';

const useMyResources = (namespace?: string) => {
  return useK8sWatchResource<MyResource[]>({
    groupVersionKind: {
      group: 'my-group.io',    // Correct separate properties
      version: 'v1',
      kind: 'MyResource',
    },
    isList: true,
    namespace,                 // Optional namespace filter
    optional: true,            // Won't fail if CRD doesn't exist
  });
};

// Usage in component
const MyComponent: React.FC = () => {
  const [resources, loaded, loadError] = useMyResources('my-namespace');
  
  if (loadError) {
    return <div>Error loading resources: {loadError.message}</div>;
  }
  
  if (!loaded) {
    return <div>Loading...</div>;
  }
  
  return <div>{resources.length} resources found</div>;
};
```

#### One-time Resource Fetching with k8sGet
```typescript
import { k8sGet } from '@openshift-console/dynamic-plugin-sdk';

const fetchSpecificResource = async (name: string, namespace: string) => {
  try {
    const resource = await k8sGet<MyResource>({
      model: {
        groupVersionKind: {
          group: 'my-group.io',
          version: 'v1', 
          kind: 'MyResource',
        }
      },
      name,
      ns: namespace
    });
    return resource;
  } catch (error) {
    console.error('Failed to fetch resource:', error);
    throw error;
  }
};
```

#### Common API Group Examples
```typescript
// Core Kubernetes resources (no group)
const podModel = {
  groupVersionKind: {
    group: '',               // Empty string for core resources
    version: 'v1',
    kind: 'Pod'
  }
};

// Apps group
const deploymentModel = {
  groupVersionKind: {
    group: 'apps',
    version: 'v1', 
    kind: 'Deployment'
  }
};

// OpenShift specific
const routeModel = {
  groupVersionKind: {
    group: 'route.openshift.io',
    version: 'v1',
    kind: 'Route'  
  }
};

// Custom Resource
const myResourceModel = {
  groupVersionKind: {
    group: 'example.com',
    version: 'v1alpha1',
    kind: 'MyCustomResource'
  }
};
```

### Custom Hooks for Complex Logic
```typescript
import { useState, useEffect } from 'react';
import { consoleFetch } from '@openshift-console/dynamic-plugin-sdk';

const useMetrics = (resource: MyResource) => {
  const [metrics, setMetrics] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchMetrics = async () => {
      try {
        setLoading(true);
        const response = await consoleFetch(
          `/api/v1/metrics/${resource.metadata.name}`
        );
        const data = await response.json();
        setMetrics(data);
      } catch (err) {
        setError(err);
      } finally {
        setLoading(false);
      }
    };

    if (resource) {
      fetchMetrics();
    }
  }, [resource]);

  return { metrics, loading, error };
};
```

## 6. Internationalization (i18n)

### Translation Setup
```typescript
// src/i18n.ts
import { useTranslation } from 'react-i18next';

export const useMyPluginTranslation = () => {
  return useTranslation('plugin__my-console-plugin');
};
```

### Translation Usage
```typescript
const MyComponent: React.FC = () => {
  const { t } = useMyPluginTranslation();
  
  return (
    <div>
      <h1>{t('Welcome to my plugin')}</h1>
      <p>{t('This plugin provides {{feature}}', { feature: 'advanced monitoring' })}</p>
    </div>
  );
};
```

### Locale Files Structure
```
locales/
├── en/
│   └── plugin__my-console-plugin.json
├── es/
│   └── plugin__my-console-plugin.json
└── ja/
    └── plugin__my-console-plugin.json
```

```json
// locales/en/plugin__my-console-plugin.json
{
  "Welcome to my plugin": "Welcome to my plugin",
  "This plugin provides {{feature}}": "This plugin provides {{feature}}",
  "Create {{kind}}": "Create {{kind}}",
  "Edit {{kind}}": "Edit {{kind}}"
}
```

## 7. Styling with PatternFly

### CSS Best Practices
```css
/* Use plugin prefix for all custom classes */
.my-console-plugin__container {
  padding: var(--pf-v6-global-spacer-md);
}

.my-console-plugin__card {
  background: var(--pf-v6-global-palette--grey-100);
  border: 1px solid var(--pf-v6-global-BorderColor-300);
}

.my-console-plugin__status-running {
  color: var(--pf-v6-global-palette--green-500);
}

.my-console-plugin__status-failed {
  color: var(--pf-v6-global-palette--red-500);
}

/* Never use hex colors - use CSS variables */
.my-console-plugin__highlight {
  background-color: var(--pf-v6-global-palette--blue-50);
  color: var(--pf-v6-global-palette--blue-700);
}
```

### Component Styling
```typescript
import React from 'react';
import {
  Card,
  CardTitle,
  CardBody,
  Label,
  Flex,
  FlexItem
} from '@patternfly/react-core';
import './MyComponent.css';

const MyComponent: React.FC = () => {
  return (
    <Card className="my-console-plugin__status-card">
      <CardTitle>Status Overview</CardTitle>
      <CardBody>
        <Flex>
          <FlexItem>
            <Label color="green">Running</Label>
          </FlexItem>
          <FlexItem>
            <Label color="red">Failed</Label>
          </FlexItem>
        </Flex>
      </CardBody>
    </Card>
  );
};
```

## 8. Webpack and Module Federation

### Webpack Configuration
```typescript
// webpack.config.ts
import { Configuration as WebpackConfiguration } from 'webpack';
import { Configuration as DevServerConfiguration } from 'webpack-dev-server';
import * as path from 'path';

interface Configuration extends WebpackConfiguration {
  devServer?: DevServerConfiguration;
}

const config: Configuration = {
  mode: 'development',
  entry: './src/index.ts',
  devtool: 'source-map',
  module: {
    rules: [
      {
        test: /\.tsx?$/,
        use: 'ts-loader',
        exclude: /node_modules/,
      },
      {
        test: /\.css$/,
        use: ['style-loader', 'css-loader'],
      },
    ],
  },
  plugins: [
    new ModuleFederationPlugin({
      name: 'my_console_plugin',
      filename: 'plugin-entry.js',
      exposes: {
        './MyPage': './src/components/MyPage',
        './MyListPage': './src/components/MyListPage',
      },
      shared: {
        react: { singleton: true },
        'react-dom': { singleton: true },
      },
    }),
  ],
  resolve: {
    extensions: ['.tsx', '.ts', '.js'],
    alias: {
      '@': path.resolve(__dirname, 'src'),
    },
  },
  devServer: {
    port: 9001,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
      'Access-Control-Allow-Headers': 'X-Requested-With, content-type, Authorization',
    },
  },
};

export default config;
```

## 9. Testing Strategies

### Unit Testing with Jest
```typescript
// src/components/__tests__/MyPage.test.tsx
import React from 'react';
import { render, screen } from '@testing-library/react';
import { I18nextProvider } from 'react-i18next';
import i18n from '../../utils/i18n-test';
import MyPage from '../MyPage';

describe('MyPage', () => {
  const renderWithI18n = (component: React.ReactElement) => {
    return render(
      <I18nextProvider i18n={i18n}>
        {component}
      </I18nextProvider>
    );
  };

  it('renders page title', () => {
    renderWithI18n(<MyPage />);
    expect(screen.getByRole('heading', { level: 1 })).toBeInTheDocument();
  });
});
```

### Integration Testing with Cypress
```typescript
// integration-tests/support/pages/my-page.ts
export class MyPage {
  visit(namespace?: string) {
    const url = namespace ? `/my-feature?namespace=${namespace}` : '/my-feature';
    cy.visit(url);
  }

  shouldShowTitle(title: string) {
    cy.get('[data-test="page-title"]').should('contain.text', title);
  }

  clickCreateButton() {
    cy.get('[data-test="create-button"]').click();
  }
}
```

```typescript
// integration-tests/tests/my-feature.spec.ts
import { MyPage } from '../support/pages/my-page';

describe('My Feature', () => {
  const page = new MyPage();

  it('should display the my feature page', () => {
    page.visit();
    page.shouldShowTitle('My Feature');
  });
});
```

## 10. Development Workflow

### Local Development

**⚠️ IMPORTANT: Plugin Testing Requirements**

To test your console plugin, you MUST run both the development server AND the OpenShift Console container. Running only the development server (`npm run start`) is insufficient for testing because:

1. **Plugin Loading**: The console must load your plugin via module federation
2. **Authentication**: Console APIs require proper authentication context
3. **Extension Points**: Navigation items, routes, and other extensions only work within the full console
4. **K8s API Access**: Resource operations require the console's proxy to the cluster APIs

#### Complete Development Setup
```bash
# 1. Install dependencies
npm install

# 2. Login to OpenShift cluster (REQUIRED)
oc login https://your-cluster-api:6443

# 3. Start plugin development server (serves plugin assets)
npm run start
# This starts webpack dev server on http://localhost:9001

# 4. Start OpenShift Console with plugin enabled (REQUIRED FOR TESTING)
npm run start-console
# This starts console container on http://localhost:9000
# The console will load your plugin from the dev server

# 5. Navigate to http://localhost:9000 to test your plugin
```

#### Testing Workflow
```bash
# After making changes to your plugin:
# 1. Webpack dev server automatically rebuilds (from step 3)
# 2. Refresh browser at http://localhost:9000 to see changes
# 3. Check browser console for any plugin loading errors

# Run automated tests
npm run test                    # Unit tests
npm run test-cypress-headless   # E2E tests

# Code quality checks
npm run lint                    # ESLint + Stylelint
```

#### Troubleshooting Plugin Loading
- Check browser dev tools Network tab for plugin loading errors
- Verify `console-extensions.json` matches your `exposedModules` in package.json
- Ensure your components are properly exported
- Check the console container logs for plugin registration errors

### Development Scripts
```json
{
  "scripts": {
    "start": "webpack serve --config webpack.config.ts",
    "start-console": "./scripts/start-console.sh",
    "build": "webpack --mode production",
    "test": "jest",
    "test-cypress": "cypress open",
    "test-cypress-headless": "cypress run",
    "lint": "eslint src --ext .ts,.tsx --fix && stylelint 'src/**/*.css' --fix",
    "i18n": "i18next-scanner --config i18next-scanner.config.js"
  }
}
```

## 11. Common Extension Patterns

### Resource Actions
```typescript
// src/actions/my-resource-actions.ts
import { Action } from '@openshift-console/dynamic-plugin-sdk';
import { MyResource } from '../types';

export const myResourceActions = (
  kindObj: K8sKind,
  obj: MyResource
): Action[] => {
  return [
    {
      id: 'restart-my-resource',
      label: 'Restart',
      icon: <RestartIcon />,
      cta: {
        href: `/api/v1/my-resources/${obj.metadata.namespace}/${obj.metadata.name}/restart`,
        external: true,
      },
      accessReview: {
        group: 'my-group.io',
        resource: 'myresources',
        verb: 'patch',
        name: obj.metadata.name,
        namespace: obj.metadata.namespace,
      },
    },
  ];
};
```

### Custom Status Components
```typescript
// src/components/MyResourceStatus.tsx
import React from 'react';
import { Label, Spinner } from '@patternfly/react-core';
import { MyResource } from '../types';

interface MyResourceStatusProps {
  resource: MyResource;
}

export const MyResourceStatus: React.FC<MyResourceStatusProps> = ({ resource }) => {
  const status = resource.status?.phase;
  
  switch (status) {
    case 'Running':
      return <Label color="green">Running</Label>;
    case 'Failed':
      return <Label color="red">Failed</Label>;
    case 'Pending':
      return (
        <>
          <Spinner size="md" />
          <Label color="blue">Pending</Label>
        </>
      );
    default:
      return <Label color="grey">Unknown</Label>;
  }
};
```

### Modal Forms
```typescript
// src/components/CreateMyResourceModal.tsx
import React from 'react';
import {
  Modal,
  ModalVariant,
  Form,
  FormGroup,
  TextInput,
  Button,
  ActionGroup,
} from '@patternfly/react-core';
import { k8sCreate } from '@openshift-console/dynamic-plugin-sdk';

interface CreateMyResourceModalProps {
  isOpen: boolean;
  onClose: () => void;
  namespace: string;
}

export const CreateMyResourceModal: React.FC<CreateMyResourceModalProps> = ({
  isOpen,
  onClose,
  namespace,
}) => {
  const [name, setName] = React.useState('');
  const [isLoading, setIsLoading] = React.useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    
    try {
      await k8sCreate({
        model: {
          apiGroup: 'my-group.io',
          apiVersion: 'v1',
          kind: 'MyResource',
        },
        data: {
          apiVersion: 'my-group.io/v1',
          kind: 'MyResource',
          metadata: {
            name,
            namespace,
          },
          spec: {
            // resource spec
          },
        },
      });
      onClose();
    } catch (error) {
      console.error('Failed to create resource:', error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Modal
      variant={ModalVariant.medium}
      title="Create My Resource"
      isOpen={isOpen}
      onClose={onClose}
    >
      <Form onSubmit={handleSubmit}>
        <FormGroup label="Name" isRequired>
          <TextInput
            value={name}
            onChange={(value) => setName(value)}
            isRequired
          />
        </FormGroup>
        <ActionGroup>
          <Button
            type="submit"
            variant="primary"
            isLoading={isLoading}
          >
            Create
          </Button>
          <Button variant="link" onClick={onClose}>
            Cancel
          </Button>
        </ActionGroup>
      </Form>
    </Modal>
  );
};
```

## 12. Performance Optimization

### Code Splitting
```typescript
// Use React.lazy for code splitting
const MyLargeComponent = React.lazy(() => import('./MyLargeComponent'));

const MyPage: React.FC = () => {
  return (
    <div>
      <Suspense fallback={<Spinner />}>
        <MyLargeComponent />
      </Suspense>
    </div>
  );
};
```

### Memoization
```typescript
// Use React.memo for component optimization
export const MyExpensiveComponent = React.memo<MyProps>(({ data }) => {
  const processedData = useMemo(() => {
    return processLargeDataSet(data);
  }, [data]);

  return <div>{/* render processed data */}</div>;
});

// Use useCallback for event handlers
const MyComponent: React.FC = () => {
  const handleClick = useCallback((id: string) => {
    // handle click
  }, []);

  return <MyList onItemClick={handleClick} />;
};
```

## 13. Deployment

### Container Image Build
```dockerfile
# Dockerfile
FROM registry.access.redhat.com/ubi8/nodejs-16 AS builder
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM registry.access.redhat.com/ubi8/nginx-120
COPY --from=builder /opt/app-root/src/dist /opt/app-root/src
COPY nginx.conf /etc/nginx/nginx.conf
CMD nginx -g "daemon off;"
```

### Helm Chart
```yaml
# charts/my-console-plugin/values.yaml
plugin:
  image: quay.io/my-org/my-console-plugin:latest
  replicas: 1
  port: 9443
  securityContext:
    enabled: true
    runAsNonRoot: true

console:
  enabled: true

service:
  type: ClusterIP
  port: 9443
  targetPort: 9443

route:
  enabled: true
  host: ""
  tls:
    termination: reencrypt
    insecureEdgeTerminationPolicy: Redirect
```

```yaml
# charts/my-console-plugin/templates/consoleplugin.yaml
apiVersion: console.openshift.io/v1
kind: ConsolePlugin
metadata:
  name: {{ .Values.plugin.name }}
spec:
  displayName: {{ .Values.plugin.displayName }}
  service:
    name: {{ .Values.plugin.name }}
    namespace: {{ .Release.Namespace }}
    port: {{ .Values.service.port }}
    basePath: '/'
  proxy:
    - type: Service
      alias: my-backend-service
      authorize: true
      service:
        name: my-backend-service
        namespace: {{ .Release.Namespace }}
        port: 8080
```

## 14. Security Best Practices

### Access Control
```typescript
// Check user permissions before rendering actions
import { useAccessReview } from '@openshift-console/dynamic-plugin-sdk';

const MyResourceActions: React.FC = ({ resource }) => {
  const [canDelete] = useAccessReview({
    group: 'my-group.io',
    resource: 'myresources',
    verb: 'delete',
    name: resource.metadata.name,
    namespace: resource.metadata.namespace,
  });

  return (
    <ActionsMenu
      actions={[
        ...(canDelete ? [deleteAction] : []),
        editAction,
      ]}
    />
  );
};
```

### Secure API Calls
```typescript
// Use console proxy for backend services
const fetchBackendData = async (resourceName: string) => {
  const response = await consoleFetch(
    `/api/proxy/plugin/my-console-plugin/my-backend-service/api/v1/data/${resourceName}`
  );
  return response.json();
};
```

## 15. Troubleshooting Common Issues

### Plugin Not Loading
- Check `console-extensions.json` syntax
- Verify `exposedModules` mapping in `package.json`
- Ensure webpack dev server is running with CORS headers
- Check browser console for JavaScript errors

### Styling Issues
- Verify CSS class prefixes match plugin name
- Use PatternFly CSS variables instead of hex colors
- Check stylelint rules aren't being violated
- Test in both light and dark modes

### Translation Issues
- Check i18n namespace matches plugin name with `plugin__` prefix
- Run `npm run i18n` after adding new translation keys
- Verify locale files are correctly formatted JSON

### Build Failures
- Update dependencies to compatible versions
- Check TypeScript configuration for strict mode issues
- Verify webpack configuration matches current versions

## Quick Reference

### Essential Commands
```bash
npm run start                    # Start dev server
npm run start-console           # Start console
npm run build                   # Production build
npm run lint                    # Lint and fix code
npm run i18n                    # Update translations
npm run test-cypress-headless   # Run e2e tests
```

### Key Extension Types
- `console.page/route` - Add new pages
- `console.navigation/href` - Add navigation links
- `console.page/resource/list` - Resource list pages
- `console.page/resource/details` - Resource detail pages
- `console.action/provider` - Resource actions
- `console.tab` - Add tabs to existing pages

### Critical Files
- `console-extensions.json` - Plugin extensions
- `package.json` `consolePlugin` - Plugin metadata
- `webpack.config.ts` - Module federation
- `tsconfig.json` - TypeScript config
- `locales/` - Translation files

This skill provides the foundation for developing robust, scalable OpenShift Console plugins that follow best practices and integrate seamlessly with the OpenShift Console ecosystem.