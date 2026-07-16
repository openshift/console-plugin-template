---
name: openshift-console-plugin-components
description: React component development patterns and best practices for OpenShift Console plugins
---

# OpenShift Console Plugin Components

This skill covers React component development patterns and best practices for building user interfaces in OpenShift Console plugins. Learn how to create maintainable, accessible, and performant components.

## Component Development Patterns

### Base Page Component Template

```typescript
import React from 'react';
import {
  Page,
  PageSection,
  Title,
  Card,
  CardBody
} from '@patternfly/react-core';
import { useTranslation } from 'react-i18next';

interface MyPageProps {
  // Define props interface
}

const MyPage: React.FC<MyPageProps> = (props) => {
  const { t } = useTranslation('plugin__my-console-plugin');

  return (
    <Page>
      <PageSection variant="light">
        <Title headingLevel="h1">{t('My Page Title')}</Title>
      </PageSection>
      <PageSection>
        <Card>
          <CardBody>
            {t('Page content goes here')}
          </CardBody>
        </Card>
      </PageSection>
    </Page>
  );
};

export default MyPage;
```

### Resource List Component Pattern

```typescript
import React from 'react';
import {
  Page,
  PageSection,
  Title,
  Alert
} from '@patternfly/react-core';
import {
  Table,
  Thead,
  Tbody,
  Tr,
  Th,
  Td,
  TableComposable
} from '@patternfly/react-table';
import {
  useK8sWatchResource,
  ListPageHeader,
  ListPageBody,
  VirtualizedTable,
  TableColumn,
  RowFunction
} from '@openshift-console/dynamic-plugin-sdk';
import { useTranslation } from 'react-i18next';
import { MyResource } from '../types';

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
      props: { className: 'pf-m-width-30' },
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
    {
      title: t('Created'),
      id: 'created',
      transforms: [],
      props: { className: 'pf-m-width-15' },
    },
  ];

  const Row: RowFunction<MyResource> = ({ obj, activeColumnIDs }) => (
    <>
      <Td dataLabel={columns[0].title}>
        <ResourceLink
          kind="MyResource"
          name={obj.metadata?.name}
          namespace={obj.metadata?.namespace}
        />
      </Td>
      <Td dataLabel={columns[1].title}>
        {obj.metadata?.namespace && (
          <ResourceLink kind="Namespace" name={obj.metadata.namespace} />
        )}
      </Td>
      <Td dataLabel={columns[2].title}>
        <Label color={obj.status?.phase === 'Ready' ? 'green' : 'red'}>
          {obj.status?.phase || 'Unknown'}
        </Label>
      </Td>
      <Td dataLabel={columns[3].title}>
        <Timestamp timestamp={obj.metadata?.creationTimestamp} />
      </Td>
    </>
  );

  if (loadError) {
    return <Alert variant="danger" title={t('Error loading resources')} />;
  }

  return (
    <Page>
      <ListPageHeader title={t('My Resources')} />
      <ListPageBody>
        <VirtualizedTable
          data={resources}
          unfilteredData={resources}
          loaded={loaded}
          loadError={loadError}
          columns={columns}
          Row={Row}
        />
      </ListPageBody>
    </Page>
  );
};

export default MyResourceList;
```

### Resource Details Component Pattern

```typescript
import React from 'react';
import { useParams } from 'react-router-dom';
import {
  Page,
  PageSection,
  Card,
  CardBody,
  Alert
} from '@patternfly/react-core';
import {
  useK8sWatchResource,
  DetailsPage,
  navFactory,
  viewYamlComponent
} from '@openshift-console/dynamic-plugin-sdk';
import { useTranslation } from 'react-i18next';
import { MyResource } from '../types';

interface RouteParams {
  ns: string;
  name: string;
}

const MyResourceDetailsPage: React.FC = () => {
  const { t } = useTranslation('plugin__my-console-plugin');
  const { ns, name } = useParams<RouteParams>();
  
  const [resource, loaded, loadError] = useK8sWatchResource<MyResource>({
    groupVersionKind: {
      group: 'my-group.io',
      version: 'v1',
      kind: 'MyResource',
    },
    name,
    namespace: ns,
  });

  const MyResourceDetails: React.FC<{ obj: MyResource }> = ({ obj }) => (
    <Card>
      <CardBody>
        <DescriptionList>
          <DescriptionListGroup>
            <DescriptionListTerm>{t('Status')}</DescriptionListTerm>
            <DescriptionListDescription>
              <Label color={obj.status?.phase === 'Ready' ? 'green' : 'red'}>
                {obj.status?.phase || 'Unknown'}
              </Label>
            </DescriptionListDescription>
          </DescriptionListGroup>
          <DescriptionListGroup>
            <DescriptionListTerm>{t('Message')}</DescriptionListTerm>
            <DescriptionListDescription>
              {obj.status?.message || t('No message')}
            </DescriptionListDescription>
          </DescriptionListGroup>
        </DescriptionList>
      </CardBody>
    </Card>
  );

  const pages = [
    {
      href: '',
      name: t('Details'),
      component: MyResourceDetails,
    },
    {
      href: 'yaml',
      name: t('YAML'),
      component: viewYamlComponent,
    },
  ];

  return (
    <DetailsPage
      data={resource}
      loaded={loaded}
      loadError={loadError}
      kind="MyResource"
      name={name}
      namespace={ns}
      pages={pages}
    />
  );
};

export default MyResourceDetailsPage;
```

### Modal Component Pattern

```typescript
import React, { useState } from 'react';
import {
  Modal,
  ModalVariant,
  Form,
  FormGroup,
  TextInput,
  Button,
  Alert
} from '@patternfly/react-core';
import { k8sCreate } from '@openshift-console/dynamic-plugin-sdk';
import { useTranslation } from 'react-i18next';
import { MyResource } from '../types';

interface CreateResourceModalProps {
  isOpen: boolean;
  onClose: () => void;
  namespace: string;
}

const CreateResourceModal: React.FC<CreateResourceModalProps> = ({
  isOpen,
  onClose,
  namespace
}) => {
  const { t } = useTranslation('plugin__my-console-plugin');
  const [name, setName] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string>('');

  const handleSubmit = async () => {
    setLoading(true);
    setError('');
    
    try {
      const resource: MyResource = {
        apiVersion: 'my-group.io/v1',
        kind: 'MyResource',
        metadata: {
          name,
          namespace,
        },
        spec: {
          // Add spec properties
        },
      };

      await k8sCreate({
        model: {
          groupVersionKind: {
            group: 'my-group.io',
            version: 'v1',
            kind: 'MyResource',
          },
        },
        data: resource,
      });

      onClose();
      setName('');
    } catch (err) {
      setError(err.message || t('Failed to create resource'));
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal
      variant={ModalVariant.medium}
      title={t('Create My Resource')}
      isOpen={isOpen}
      onClose={onClose}
      actions={[
        <Button
          key="create"
          variant="primary"
          onClick={handleSubmit}
          isLoading={loading}
          isDisabled={!name || loading}
        >
          {t('Create')}
        </Button>,
        <Button key="cancel" variant="link" onClick={onClose}>
          {t('Cancel')}
        </Button>,
      ]}
    >
      {error && <Alert variant="danger" title={error} className="pf-u-mb-md" />}
      <Form>
        <FormGroup label={t('Name')} isRequired fieldId="resource-name">
          <TextInput
            id="resource-name"
            value={name}
            onChange={setName}
            isRequired
          />
        </FormGroup>
      </Form>
    </Modal>
  );
};

export default CreateResourceModal;
```

## Component Patterns and Best Practices

### Error Handling Pattern

```typescript
import React from 'react';
import { Alert, Button } from '@patternfly/react-core';
import { useTranslation } from 'react-i18next';

interface ErrorBoundaryState {
  hasError: boolean;
  error?: Error;
}

class ErrorBoundary extends React.Component<React.PropsWithChildren<{}>, ErrorBoundaryState> {
  constructor(props: React.PropsWithChildren<{}>) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('Component error:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <Alert 
          variant="danger" 
          title="Something went wrong"
          actionLinks={
            <Button variant="link" onClick={() => window.location.reload()}>
              Reload page
            </Button>
          }
        >
          {this.state.error?.message}
        </Alert>
      );
    }

    return this.props.children;
  }
}
```

### Loading States Pattern

```typescript
import React from 'react';
import { Spinner, Bullseye, EmptyState, EmptyStateIcon, Title } from '@patternfly/react-core';
import { CubesIcon } from '@patternfly/react-icons';
import { useTranslation } from 'react-i18next';

interface LoadingStateProps {
  loaded: boolean;
  data: any[];
  error?: Error;
  children: React.ReactNode;
}

const LoadingState: React.FC<LoadingStateProps> = ({ loaded, data, error, children }) => {
  const { t } = useTranslation('plugin__my-console-plugin');

  if (error) {
    return (
      <EmptyState>
        <EmptyStateIcon icon={CubesIcon} />
        <Title headingLevel="h4">{t('Error loading data')}</Title>
        <div>{error.message}</div>
      </EmptyState>
    );
  }

  if (!loaded) {
    return (
      <Bullseye>
        <Spinner />
      </Bullseye>
    );
  }

  if (loaded && data.length === 0) {
    return (
      <EmptyState>
        <EmptyStateIcon icon={CubesIcon} />
        <Title headingLevel="h4">{t('No data found')}</Title>
      </EmptyState>
    );
  }

  return <>{children}</>;
};
```

### Custom Hooks Pattern

```typescript
import { useState, useEffect } from 'react';
import { useK8sWatchResource } from '@openshift-console/dynamic-plugin-sdk';
import { MyResource } from '../types';

// Custom hook for resource management
export const useMyResources = (namespace?: string) => {
  const [resources, loaded, loadError] = useK8sWatchResource<MyResource[]>({
    groupVersionKind: {
      group: 'my-group.io',
      version: 'v1',
      kind: 'MyResource',
    },
    isList: true,
    namespace,
  });

  return { resources, loaded, loadError };
};

// Custom hook for resource filtering
export const useFilteredResources = (resources: MyResource[], filter: string) => {
  const [filteredResources, setFilteredResources] = useState<MyResource[]>([]);

  useEffect(() => {
    if (!filter) {
      setFilteredResources(resources);
      return;
    }

    const filtered = resources.filter(resource =>
      resource.metadata?.name?.toLowerCase().includes(filter.toLowerCase())
    );
    setFilteredResources(filtered);
  }, [resources, filter]);

  return filteredResources;
};

// Custom hook for resource status
export const useResourceStatus = (resource: MyResource) => {
  const isReady = resource.status?.phase === 'Ready';
  const hasError = resource.status?.phase === 'Error';
  const isPending = resource.status?.phase === 'Pending';

  return { isReady, hasError, isPending };
};
```

### TypeScript Interface Patterns

```typescript
import { K8sResourceCommon } from '@openshift-console/dynamic-plugin-sdk';

// Base resource interface
export interface MyResourceSpec {
  replicas?: number;
  selector?: {
    matchLabels?: Record<string, string>;
  };
  template?: {
    metadata?: {
      labels?: Record<string, string>;
    };
    spec?: {
      containers?: Array<{
        name: string;
        image: string;
        ports?: Array<{
          containerPort: number;
          protocol?: string;
        }>;
      }>;
    };
  };
}

export interface MyResourceStatus {
  phase?: 'Pending' | 'Ready' | 'Error';
  message?: string;
  readyReplicas?: number;
  replicas?: number;
  conditions?: Array<{
    type: string;
    status: string;
    lastTransitionTime?: string;
    message?: string;
  }>;
}

export interface MyResource extends K8sResourceCommon {
  spec: MyResourceSpec;
  status?: MyResourceStatus;
}

// Component props interfaces
export interface MyResourceRowProps {
  obj: MyResource;
  index: number;
  isScrolling: boolean;
  style: React.CSSProperties;
}

export interface MyResourceDetailsProps {
  resource: MyResource;
  loaded: boolean;
  loadError?: Error;
}
```

## Performance Optimization

### React.memo for Component Optimization

```typescript
import React from 'react';
import { MyResource } from '../types';

interface MyResourceCardProps {
  resource: MyResource;
  onSelect?: (resource: MyResource) => void;
}

const MyResourceCard: React.FC<MyResourceCardProps> = React.memo(({ resource, onSelect }) => {
  const handleClick = React.useCallback(() => {
    onSelect?.(resource);
  }, [resource, onSelect]);

  return (
    <Card isClickable onClick={handleClick}>
      <CardTitle>{resource.metadata?.name}</CardTitle>
      <CardBody>{resource.status?.phase}</CardBody>
    </Card>
  );
});

MyResourceCard.displayName = 'MyResourceCard';

export default MyResourceCard;
```

### Lazy Loading Components

```typescript
import React, { Suspense } from 'react';
import { Spinner, Bullseye } from '@patternfly/react-core';

// Lazy load heavy components
const MyLargeComponent = React.lazy(() => import('./MyLargeComponent'));

const MyPage: React.FC = () => {
  const [showLargeComponent, setShowLargeComponent] = useState(false);

  return (
    <Page>
      <PageSection>
        <Button onClick={() => setShowLargeComponent(true)}>
          Load Large Component
        </Button>
        {showLargeComponent && (
          <Suspense fallback={<Bullseye><Spinner /></Bullseye>}>
            <MyLargeComponent />
          </Suspense>
        )}
      </PageSection>
    </Page>
  );
};
```

## Accessibility Best Practices

### ARIA Labels and Descriptions

```typescript
import React from 'react';
import { Button, Card, CardTitle, CardBody } from '@patternfly/react-core';

const AccessibleComponent: React.FC = () => {
  return (
    <Card>
      <CardTitle>
        <span id="card-title">Resource Status</span>
      </CardTitle>
      <CardBody>
        <Button
          aria-label="Restart resource"
          aria-describedby="restart-description"
        >
          Restart
        </Button>
        <div id="restart-description" className="sr-only">
          This will restart the resource and may cause temporary downtime
        </div>
      </CardBody>
    </Card>
  );
};
```

### Keyboard Navigation

```typescript
import React, { useState } from 'react';
import { Card, CardBody } from '@patternfly/react-core';

const KeyboardNavigableCard: React.FC = () => {
  const [focused, setFocused] = useState(false);

  const handleKeyDown = (event: React.KeyboardEvent) => {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      // Handle selection
    }
  };

  return (
    <Card
      tabIndex={0}
      onFocus={() => setFocused(true)}
      onBlur={() => setFocused(false)}
      onKeyDown={handleKeyDown}
      className={focused ? 'pf-m-focus' : ''}
      role="button"
      aria-label="Selectable resource card"
    >
      <CardBody>Resource content</CardBody>
    </Card>
  );
};
```

## Related Skills

- [openshift-console-plugin-styling](../openshift-console-plugin-styling/SKILL.md) - UI design and PatternFly usage
- [openshift-console-plugin-data](../openshift-console-plugin-data/SKILL.md) - Data fetching and state management
- [openshift-console-plugin-i18n](../openshift-console-plugin-i18n/SKILL.md) - Internationalization in components
- [openshift-console-plugin-development](../openshift-console-plugin-development/SKILL.md) - Testing component patterns

## Component Checklist

- [ ] Use TypeScript interfaces for all props
- [ ] Implement proper error handling
- [ ] Add loading states for async operations
- [ ] Include accessibility attributes (ARIA labels)
- [ ] Use i18n for all user-facing strings
- [ ] Follow PatternFly design patterns
- [ ] Implement keyboard navigation where needed
- [ ] Use React.memo for performance optimization
- [ ] Add proper error boundaries
- [ ] Include comprehensive prop validation