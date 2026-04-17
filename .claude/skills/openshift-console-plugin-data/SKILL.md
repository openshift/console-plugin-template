---
name: openshift-console-plugin-data
description: K8s data fetching, SDK helpers, and state management for OpenShift Console plugins
---

# OpenShift Console Plugin Data Management

This skill covers K8s data fetching, SDK helpers, and state management patterns for OpenShift Console plugins. Learn how to efficiently work with Kubernetes resources and manage application state.

## K8s SDK Helpers for Resource Operations

**⚠️ CRITICAL: Always use SDK helpers for Kubernetes resource operations**

**DO NOT construct API paths manually**. The console SDK provides helper functions that handle authentication, proper URL construction, error handling, and caching. Always use these instead of raw fetch calls or manual path construction.

### Core SDK Helper Functions
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

## API Groups and Versions - Critical Configuration

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

### Mapping YAML apiVersion to SDK Properties
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

## Watching Resources with useK8sWatchResource

### Basic Resource Watching
```typescript
import { useK8sWatchResource } from '@openshift-console/dynamic-plugin-sdk';
import { MyResource } from '../types';

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
    return <Alert variant="danger" title={`Error loading resources: ${loadError.message}`} />;
  }
  
  if (!loaded) {
    return <Spinner />;
  }
  
  return <div>{resources.length} resources found</div>;
};
```

### Single Resource Watching
```typescript
const useSingleResource = (name: string, namespace: string) => {
  return useK8sWatchResource<MyResource>({
    groupVersionKind: {
      group: 'my-group.io',
      version: 'v1',
      kind: 'MyResource',
    },
    name,
    namespace,
  });
};
```

### Cluster-scoped Resources
```typescript
const useClusterResources = () => {
  return useK8sWatchResource<ClusterResource[]>({
    groupVersionKind: {
      group: 'config.openshift.io',
      version: 'v1',
      kind: 'ClusterVersion',
    },
    isList: true,
    // No namespace for cluster-scoped resources
  });
};
```

## One-time Resource Fetching with k8sGet

### Fetch Single Resource
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

### Fetch Multiple Resources
```typescript
import { k8sList } from '@openshift-console/dynamic-plugin-sdk';

const fetchAllResources = async (namespace?: string) => {
  try {
    const response = await k8sList({
      model: {
        groupVersionKind: {
          group: 'my-group.io',
          version: 'v1',
          kind: 'MyResource',
        }
      },
      queryParams: namespace ? { ns: namespace } : undefined
    });
    return response;
  } catch (error) {
    console.error('Failed to fetch resources:', error);
    throw error;
  }
};
```

## Resource Mutations

### Creating Resources
```typescript
import { k8sCreate } from '@openshift-console/dynamic-plugin-sdk';

const createResource = async (resourceData: MyResource) => {
  try {
    const created = await k8sCreate({
      model: {
        groupVersionKind: {
          group: 'my-group.io',
          version: 'v1',
          kind: 'MyResource',
        }
      },
      data: resourceData
    });
    return created;
  } catch (error) {
    console.error('Failed to create resource:', error);
    throw error;
  }
};
```

### Updating Resources
```typescript
import { k8sUpdate } from '@openshift-console/dynamic-plugin-sdk';

const updateResource = async (resource: MyResource, updates: Partial<MyResource>) => {
  try {
    const updatedResource = {
      ...resource,
      ...updates,
      metadata: {
        ...resource.metadata,
        ...updates.metadata,
      },
    };

    const result = await k8sUpdate({
      model: {
        groupVersionKind: {
          group: 'my-group.io',
          version: 'v1',
          kind: 'MyResource',
        }
      },
      data: updatedResource,
      name: resource.metadata?.name,
      ns: resource.metadata?.namespace
    });
    return result;
  } catch (error) {
    console.error('Failed to update resource:', error);
    throw error;
  }
};
```

### Deleting Resources
```typescript
import { k8sDelete } from '@openshift-console/dynamic-plugin-sdk';

const deleteResource = async (resource: MyResource) => {
  try {
    await k8sDelete({
      model: {
        groupVersionKind: {
          group: 'my-group.io',
          version: 'v1',
          kind: 'MyResource',
        }
      },
      resource
    });
  } catch (error) {
    console.error('Failed to delete resource:', error);
    throw error;
  }
};
```

## Common API Group Examples

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

## Custom Hooks for Complex Logic

### Resource Management Hook
```typescript
import { useState, useCallback } from 'react';
import { useK8sWatchResource, k8sCreate, k8sUpdate, k8sDelete } from '@openshift-console/dynamic-plugin-sdk';

export const useMyResourceManager = (namespace: string) => {
  const [resources, loaded, loadError] = useK8sWatchResource<MyResource[]>({
    groupVersionKind: {
      group: 'my-group.io',
      version: 'v1',
      kind: 'MyResource',
    },
    isList: true,
    namespace,
  });

  const [operationLoading, setOperationLoading] = useState(false);
  const [operationError, setOperationError] = useState<string>('');

  const createResource = useCallback(async (data: Partial<MyResource>) => {
    setOperationLoading(true);
    setOperationError('');
    try {
      const resource: MyResource = {
        apiVersion: 'my-group.io/v1',
        kind: 'MyResource',
        metadata: {
          namespace,
          ...data.metadata,
        },
        spec: data.spec || {},
      };

      await k8sCreate({
        model: {
          groupVersionKind: {
            group: 'my-group.io',
            version: 'v1',
            kind: 'MyResource',
          }
        },
        data: resource
      });
    } catch (error) {
      setOperationError(error.message);
      throw error;
    } finally {
      setOperationLoading(false);
    }
  }, [namespace]);

  const updateResource = useCallback(async (resource: MyResource, updates: Partial<MyResource>) => {
    setOperationLoading(true);
    setOperationError('');
    try {
      await k8sUpdate({
        model: {
          groupVersionKind: {
            group: 'my-group.io',
            version: 'v1',
            kind: 'MyResource',
          }
        },
        data: { ...resource, ...updates },
        name: resource.metadata?.name,
        ns: resource.metadata?.namespace
      });
    } catch (error) {
      setOperationError(error.message);
      throw error;
    } finally {
      setOperationLoading(false);
    }
  }, []);

  const deleteResource = useCallback(async (resource: MyResource) => {
    setOperationLoading(true);
    setOperationError('');
    try {
      await k8sDelete({
        model: {
          groupVersionKind: {
            group: 'my-group.io',
            version: 'v1',
            kind: 'MyResource',
          }
        },
        resource
      });
    } catch (error) {
      setOperationError(error.message);
      throw error;
    } finally {
      setOperationLoading(false);
    }
  }, []);

  return {
    resources,
    loaded,
    loadError,
    createResource,
    updateResource,
    deleteResource,
    operationLoading,
    operationError,
  };
};
```

### Metrics and Observability Hook
```typescript
import { useState, useEffect } from 'react';
import { consoleFetch } from '@openshift-console/dynamic-plugin-sdk';

interface MetricData {
  timestamp: number;
  value: number;
}

export const useMetrics = (resource: MyResource, metricName: string) => {
  const [metrics, setMetrics] = useState<MetricData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>('');

  useEffect(() => {
    const fetchMetrics = async () => {
      setLoading(true);
      setError('');
      
      try {
        const query = `my_metric{resource="${resource.metadata?.name}",namespace="${resource.metadata?.namespace}"}[5m]`;
        const response = await consoleFetch(`/api/prometheus/query_range?query=${encodeURIComponent(query)}`);
        const data = await response.json();
        
        if (data.status === 'success') {
          const values = data.data.result[0]?.values || [];
          const metricData = values.map(([timestamp, value]: [number, string]) => ({
            timestamp: timestamp * 1000,
            value: parseFloat(value),
          }));
          setMetrics(metricData);
        }
      } catch (err) {
        setError(err.message || 'Failed to fetch metrics');
      } finally {
        setLoading(false);
      }
    };

    if (resource.metadata?.name && metricName) {
      fetchMetrics();
    }
  }, [resource.metadata?.name, resource.metadata?.namespace, metricName]);

  return { metrics, loading, error };
};
```

## State Management Patterns

### Resource Status Hook
```typescript
import { useMemo } from 'react';

export const useResourceStatus = (resource: MyResource) => {
  return useMemo(() => {
    const phase = resource.status?.phase;
    const conditions = resource.status?.conditions || [];
    
    const isReady = phase === 'Ready';
    const isError = phase === 'Error';
    const isPending = phase === 'Pending';
    
    const lastCondition = conditions[conditions.length - 1];
    const statusMessage = resource.status?.message || lastCondition?.message || '';
    
    const readyCondition = conditions.find(c => c.type === 'Ready');
    const isHealthy = readyCondition?.status === 'True';
    
    return {
      phase,
      isReady,
      isError,
      isPending,
      isHealthy,
      statusMessage,
      conditions,
    };
  }, [resource.status]);
};
```

### Resource Filter Hook
```typescript
import { useMemo } from 'react';

export const useResourceFilter = <T extends { metadata?: { name?: string; labels?: Record<string, string> } }>(
  resources: T[],
  filters: {
    nameFilter?: string;
    labelSelector?: Record<string, string>;
    statusFilter?: (resource: T) => boolean;
  }
) => {
  return useMemo(() => {
    let filtered = resources;

    if (filters.nameFilter) {
      const nameFilter = filters.nameFilter.toLowerCase();
      filtered = filtered.filter(resource =>
        resource.metadata?.name?.toLowerCase().includes(nameFilter)
      );
    }

    if (filters.labelSelector) {
      filtered = filtered.filter(resource => {
        const labels = resource.metadata?.labels || {};
        return Object.entries(filters.labelSelector).every(([key, value]) =>
          labels[key] === value
        );
      });
    }

    if (filters.statusFilter) {
      filtered = filtered.filter(filters.statusFilter);
    }

    return filtered;
  }, [resources, filters.nameFilter, filters.labelSelector, filters.statusFilter]);
};
```

## Error Handling Patterns

### Resource Operation with Retry
```typescript
import { useState, useCallback } from 'react';

export const useResourceOperationWithRetry = () => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string>('');
  const [retryCount, setRetryCount] = useState(0);

  const executeOperation = useCallback(async (
    operation: () => Promise<any>,
    maxRetries = 3,
    retryDelay = 1000
  ) => {
    setLoading(true);
    setError('');
    setRetryCount(0);

    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        const result = await operation();
        setLoading(false);
        return result;
      } catch (err) {
        setRetryCount(attempt + 1);
        
        if (attempt === maxRetries) {
          setError(err.message || 'Operation failed');
          setLoading(false);
          throw err;
        }
        
        // Wait before retrying
        await new Promise(resolve => setTimeout(resolve, retryDelay * (attempt + 1)));
      }
    }
  }, []);

  return {
    executeOperation,
    loading,
    error,
    retryCount,
  };
};
```

## Performance Optimization

### Stable References
```typescript
import { useMemo } from 'react';

// Stable empty arrays to prevent infinite re-renders
const EMPTY_RESOURCES_ARRAY = [] as MyResource[];
const EMPTY_STRINGS_ARRAY = [] as string[];

export const useStableResourceData = (resources: MyResource[] | undefined) => {
  return useMemo(() => {
    return resources || EMPTY_RESOURCES_ARRAY;
  }, [resources]);
};

export const useResourceNames = (resources: MyResource[]) => {
  return useMemo(() => {
    if (!resources.length) return EMPTY_STRINGS_ARRAY;
    return resources.map(r => r.metadata?.name).filter(Boolean) as string[];
  }, [resources]);
};
```

## Related Skills

- [openshift-console-plugin-components](../openshift-console-plugin-components/SKILL.md) - React component patterns using data
- [openshift-console-plugin-setup](../openshift-console-plugin-setup/SKILL.md) - TypeScript configuration for data types
- [openshift-console-plugin-advanced](../openshift-console-plugin-advanced/SKILL.md) - Performance optimization techniques
- [openshift-console-plugin-development](../openshift-console-plugin-development/SKILL.md) - Testing data hooks and operations

## Data Management Checklist

- [ ] Use SDK helpers for all K8s operations (never construct API paths)
- [ ] Specify API group and version as separate properties  
- [ ] Implement proper error handling for all resource operations
- [ ] Use stable array references to prevent infinite re-renders
- [ ] Add TypeScript interfaces for all resource types
- [ ] Implement loading states for async operations
- [ ] Use custom hooks for complex data logic
- [ ] Add retry logic for critical operations
- [ ] Optimize with useMemo for expensive computations
- [ ] Handle edge cases (empty data, errors, missing resources)