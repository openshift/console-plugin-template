---
name: openshift-console-plugin-advanced
description: Advanced patterns, performance optimization, security, and complex plugin development for OpenShift Console
---

# OpenShift Console Plugin Advanced Development

This skill covers advanced patterns, performance optimization, security best practices, and complex plugin development techniques for experienced OpenShift Console plugin developers.

## Performance Optimization

### Code Splitting and Lazy Loading

```typescript
// Dynamic imports for large components
import React, { Suspense } from 'react';
import { Spinner, Bullseye } from '@patternfly/react-core';

// Lazy load heavy components
const MyLargeComponent = React.lazy(() => import('./MyLargeComponent'));
const MyChartComponent = React.lazy(() => import('./MyChartComponent'));

const MyPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState('overview');

  return (
    <Page>
      <Tabs activeKey={activeTab} onSelect={setActiveTab}>
        <Tab eventKey="overview" title="Overview">
          <div>Overview content (loaded immediately)</div>
        </Tab>
        <Tab eventKey="charts" title="Charts">
          <Suspense fallback={<Bullseye><Spinner /></Bullseye>}>
            <MyChartComponent />
          </Suspense>
        </Tab>
        <Tab eventKey="advanced" title="Advanced">
          <Suspense fallback={<Bullseye><Spinner /></Bullseye>}>
            <MyLargeComponent />
          </Suspense>
        </Tab>
      </Tabs>
    </Page>
  );
};
```

### Webpack Bundle Optimization

```typescript
// webpack.config.ts
import * as webpack from 'webpack';
import { BundleAnalyzerPlugin } from 'webpack-bundle-analyzer';

const config: webpack.Configuration = {
  optimization: {
    splitChunks: {
      chunks: 'all',
      cacheGroups: {
        vendor: {
          test: /[\\/]node_modules[\\/]/,
          name: 'vendors',
          chunks: 'all',
          priority: 10,
        },
        patternfly: {
          test: /[\\/]node_modules[\\/]@patternfly[\\/]/,
          name: 'patternfly',
          chunks: 'all',
          priority: 20,
        },
        common: {
          minChunks: 2,
          chunks: 'all',
          name: 'common',
          priority: 5,
        },
      },
    },
    minimizer: [
      new TerserPlugin({
        terserOptions: {
          compress: {
            drop_console: process.env.NODE_ENV === 'production',
            drop_debugger: process.env.NODE_ENV === 'production',
          },
          mangle: true,
        },
      }),
    ],
  },
  plugins: [
    // Analyze bundle in development
    process.env.ANALYZE && new BundleAnalyzerPlugin(),
  ].filter(Boolean),
};
```

### Memoization and Performance Hooks

```typescript
import React, { useMemo, useCallback, useState } from 'react';

// Expensive computation memoization
export const useExpensiveCalculation = (data: MyResource[], filter: string) => {
  return useMemo(() => {
    // Only recalculate when data or filter changes
    return data
      .filter(item => item.metadata?.name?.includes(filter))
      .sort((a, b) => (a.metadata?.name || '').localeCompare(b.metadata?.name || ''))
      .map(item => ({
        ...item,
        // Expensive transformation
        computed: performExpensiveOperation(item),
      }));
  }, [data, filter]);
};

// Stable callback references
const MyExpensiveComponent = React.memo<MyProps>(({ data, onUpdate }) => {
  const [localState, setLocalState] = useState('');
  
  // Stable callback reference
  const handleUpdate = useCallback((id: string, updates: Partial<MyResource>) => {
    onUpdate(id, updates);
  }, [onUpdate]);
  
  // Memoized derived state
  const processedData = useMemo(() => {
    return data.map(item => ({
      ...item,
      displayName: item.metadata?.name || 'Unknown',
      isHealthy: item.status?.phase === 'Ready',
    }));
  }, [data]);

  return (
    <div>
      {processedData.map(item => (
        <MyResourceCard 
          key={item.metadata?.uid}
          resource={item}
          onUpdate={handleUpdate}
        />
      ))}
    </div>
  );
});

MyExpensiveComponent.displayName = 'MyExpensiveComponent';
```

### Virtual Scrolling for Large Lists

```typescript
import React from 'react';
import { FixedSizeList } from 'react-window';
import { Card, CardBody } from '@patternfly/react-core';

interface VirtualizedListProps {
  items: MyResource[];
  height: number;
  itemHeight: number;
}

const VirtualizedList: React.FC<VirtualizedListProps> = ({ items, height, itemHeight }) => {
  const Row = React.memo(({ index, style }: { index: number; style: React.CSSProperties }) => {
    const item = items[index];
    
    return (
      <div style={style}>
        <Card>
          <CardBody>
            <h4>{item.metadata?.name}</h4>
            <p>Status: {item.status?.phase}</p>
          </CardBody>
        </Card>
      </div>
    );
  });
  
  Row.displayName = 'VirtualizedRow';

  return (
    <FixedSizeList
      height={height}
      itemCount={items.length}
      itemSize={itemHeight}
      width="100%"
    >
      {Row}
    </FixedSizeList>
  );
};
```

### Resource Caching Strategies

```typescript
import { useRef, useEffect } from 'react';

// Simple cache implementation
class ResourceCache<T> {
  private cache = new Map<string, { data: T; timestamp: number; ttl: number }>();
  
  set(key: string, data: T, ttl = 300000) { // 5 minutes default
    this.cache.set(key, {
      data,
      timestamp: Date.now(),
      ttl,
    });
  }
  
  get(key: string): T | null {
    const entry = this.cache.get(key);
    if (!entry) return null;
    
    if (Date.now() - entry.timestamp > entry.ttl) {
      this.cache.delete(key);
      return null;
    }
    
    return entry.data;
  }
  
  clear() {
    this.cache.clear();
  }
}

// Global cache instance
const resourceCache = new ResourceCache<any>();

export const useCachedResource = <T>(key: string, fetcher: () => Promise<T>) => {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      const cached = resourceCache.get(key);
      if (cached) {
        setData(cached);
        setLoading(false);
        return;
      }

      try {
        setLoading(true);
        const result = await fetcher();
        resourceCache.set(key, result);
        setData(result);
      } catch (err) {
        setError(err as Error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [key, fetcher]);

  return { data, loading, error };
};
```

## Security Best Practices

### Content Security Policy (CSP)

```nginx
# nginx.conf security headers
add_header Content-Security-Policy "
  default-src 'self';
  script-src 'self' 'unsafe-inline' 'unsafe-eval';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: https:;
  font-src 'self' data:;
  connect-src 'self' https://*.openshift.com wss://*.openshift.com;
  frame-ancestors 'none';
" always;

add_header X-Frame-Options "DENY" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

### Secure API Communication

```typescript
import { consoleFetch } from '@openshift-console/dynamic-plugin-sdk';

// Secure API wrapper
class SecureApiClient {
  private baseUrl: string;
  private timeout: number;
  
  constructor(baseUrl: string, timeout = 30000) {
    this.baseUrl = baseUrl;
    this.timeout = timeout;
  }
  
  private async request<T>(
    endpoint: string, 
    options: RequestInit = {}
  ): Promise<T> {
    const url = `${this.baseUrl}${endpoint}`;
    
    // Add security headers
    const headers = {
      'Content-Type': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      ...options.headers,
    };
    
    // Create request with timeout
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), this.timeout);
    
    try {
      const response = await consoleFetch(url, {
        ...options,
        headers,
        signal: controller.signal,
      });
      
      clearTimeout(timeoutId);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      // Validate response content type
      const contentType = response.headers.get('content-type');
      if (!contentType?.includes('application/json')) {
        throw new Error('Invalid response content type');
      }
      
      return response.json();
    } catch (error) {
      clearTimeout(timeoutId);
      throw error;
    }
  }
  
  async get<T>(endpoint: string): Promise<T> {
    return this.request<T>(endpoint, { method: 'GET' });
  }
  
  async post<T>(endpoint: string, data: unknown): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }
}
```

### Input Validation and Sanitization

```typescript
import DOMPurify from 'dompurify';

// Input validation utilities
export const ValidationUtils = {
  // Kubernetes name validation
  isValidKubernetesName: (name: string): boolean => {
    const pattern = /^[a-z0-9]([-a-z0-9]*[a-z0-9])?$/;
    return pattern.test(name) && name.length <= 253;
  },
  
  // Label validation
  isValidLabel: (key: string, value: string): boolean => {
    const keyPattern = /^([a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*\/)?[a-z0-9A-Z]([-a-z0-9A-Z._]*[a-z0-9A-Z])?$/;
    const valuePattern = /^[a-z0-9A-Z]([-a-z0-9A-Z._]*[a-z0-9A-Z])?$/;
    return keyPattern.test(key) && valuePattern.test(value);
  },
  
  // Sanitize HTML content
  sanitizeHtml: (html: string): string => {
    return DOMPurify.sanitize(html, {
      ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'code'],
      ALLOWED_ATTR: [],
    });
  },
  
  // Escape shell commands
  escapeShellArg: (arg: string): string => {
    return "'" + arg.replace(/'/g, "'\"'\"'") + "'";
  },
};

// Secure form component
const SecureResourceForm: React.FC = () => {
  const [name, setName] = useState('');
  const [nameError, setNameError] = useState('');
  
  const handleNameChange = (value: string) => {
    setName(value);
    
    if (!ValidationUtils.isValidKubernetesName(value)) {
      setNameError('Name must be a valid Kubernetes resource name');
    } else {
      setNameError('');
    }
  };
  
  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    
    // Final validation before submission
    if (!ValidationUtils.isValidKubernetesName(name)) {
      alert('Invalid resource name');
      return;
    }
    
    // Submit safely validated data
    await createResource({ name });
  };
  
  return (
    <Form onSubmit={handleSubmit}>
      <FormGroup 
        label="Resource Name" 
        isRequired
        validated={nameError ? 'error' : 'default'}
        helperTextInvalid={nameError}
      >
        <TextInput
          id="resource-name"
          value={name}
          onChange={handleNameChange}
          validated={nameError ? 'error' : 'default'}
          maxLength={253}
        />
      </FormGroup>
    </Form>
  );
};
```

### Secrets and Sensitive Data Handling

```typescript
// Never store secrets in component state or props
// Use refs for temporary sensitive data

const SecurePasswordComponent: React.FC = () => {
  const passwordRef = useRef<HTMLInputElement>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  
  const handleSubmit = async () => {
    const password = passwordRef.current?.value;
    if (!password) return;
    
    try {
      setIsSubmitting(true);
      
      // Use password immediately, don't store
      await authenticateUser(password);
      
      // Clear the input immediately
      if (passwordRef.current) {
        passwordRef.current.value = '';
      }
    } finally {
      setIsSubmitting(false);
    }
  };
  
  return (
    <Form onSubmit={handleSubmit}>
      <FormGroup label="Password">
        <TextInput
          ref={passwordRef}
          type="password"
          autoComplete="current-password"
          // Don't use controlled input for passwords
        />
      </FormGroup>
      <Button type="submit" isLoading={isSubmitting}>
        Submit
      </Button>
    </Form>
  );
};
```

## Advanced Extension Patterns

### Dynamic Extension Registration

```typescript
// Dynamic extension loading based on feature flags
import { Extension } from '@openshift-console/dynamic-plugin-sdk';

interface FeatureFlags {
  experimentalFeatures: boolean;
  betaFeatures: boolean;
  adminFeatures: boolean;
}

export const getDynamicExtensions = (flags: FeatureFlags): Extension[] => {
  const extensions: Extension[] = [
    // Base extensions always loaded
    {
      type: 'console.navigation/href',
      properties: {
        id: 'my-plugin-main',
        name: '%plugin__my-console-plugin~Main%',
        href: '/my-plugin',
      },
    },
  ];
  
  // Conditional extensions
  if (flags.experimentalFeatures) {
    extensions.push({
      type: 'console.page/route',
      properties: {
        path: '/my-plugin/experimental',
        component: { $codeRef: 'ExperimentalPage' },
      },
    });
  }
  
  if (flags.betaFeatures) {
    extensions.push({
      type: 'console.tab',
      properties: {
        model: { kind: 'Pod' },
        component: { $codeRef: 'BetaTab' },
        name: '%plugin__my-console-plugin~Beta Features%',
      },
    });
  }
  
  if (flags.adminFeatures) {
    extensions.push({
      type: 'console.action/resource-provider',
      properties: {
        model: { kind: 'Node' },
        provider: { $codeRef: 'adminActions' },
      },
    });
  }
  
  return extensions;
};
```

### Custom Hook Factories

```typescript
// Advanced hook factory pattern
export const createResourceHook = <T extends K8sResourceCommon>(
  groupVersionKind: GroupVersionKind,
  options: {
    caching?: boolean;
    polling?: number;
    transform?: (data: T[]) => T[];
  } = {}
) => {
  return (namespace?: string) => {
    const [resources, loaded, loadError] = useK8sWatchResource<T[]>({
      groupVersionKind,
      isList: true,
      namespace,
    });
    
    const processedResources = useMemo(() => {
      if (!resources) return [];
      
      let processed = resources;
      
      if (options.transform) {
        processed = options.transform(processed);
      }
      
      return processed;
    }, [resources, options.transform]);
    
    // Add polling if requested
    useEffect(() => {
      if (!options.polling || !loaded) return;
      
      const interval = setInterval(() => {
        // Trigger refresh
        console.log('Polling for updates...');
      }, options.polling);
      
      return () => clearInterval(interval);
    }, [loaded, options.polling]);
    
    return {
      resources: processedResources,
      loaded,
      loadError,
      total: processedResources.length,
    };
  };
};

// Usage
const useMyResources = createResourceHook<MyResource>(
  { group: 'my-group.io', version: 'v1', kind: 'MyResource' },
  {
    caching: true,
    polling: 30000, // 30 seconds
    transform: (data) => data.filter(item => item.status?.phase !== 'Terminating'),
  }
);
```

### Advanced State Management

```typescript
// Complex state management with reducers
interface PluginState {
  resources: MyResource[];
  filters: {
    namespace?: string;
    status?: string;
    search?: string;
  };
  pagination: {
    page: number;
    perPage: number;
    total: number;
  };
  selectedItems: Set<string>;
  loading: boolean;
  error: string | null;
}

type PluginAction =
  | { type: 'SET_RESOURCES'; payload: MyResource[] }
  | { type: 'SET_FILTER'; payload: { key: keyof PluginState['filters']; value: string } }
  | { type: 'SET_PAGINATION'; payload: Partial<PluginState['pagination']> }
  | { type: 'TOGGLE_SELECTION'; payload: string }
  | { type: 'SET_LOADING'; payload: boolean }
  | { type: 'SET_ERROR'; payload: string | null };

const pluginReducer = (state: PluginState, action: PluginAction): PluginState => {
  switch (action.type) {
    case 'SET_RESOURCES':
      return {
        ...state,
        resources: action.payload,
        pagination: {
          ...state.pagination,
          total: action.payload.length,
        },
      };
      
    case 'SET_FILTER':
      return {
        ...state,
        filters: {
          ...state.filters,
          [action.payload.key]: action.payload.value,
        },
        pagination: {
          ...state.pagination,
          page: 1, // Reset to first page when filtering
        },
      };
      
    case 'SET_PAGINATION':
      return {
        ...state,
        pagination: {
          ...state.pagination,
          ...action.payload,
        },
      };
      
    case 'TOGGLE_SELECTION':
      const newSelection = new Set(state.selectedItems);
      if (newSelection.has(action.payload)) {
        newSelection.delete(action.payload);
      } else {
        newSelection.add(action.payload);
      }
      return {
        ...state,
        selectedItems: newSelection,
      };
      
    case 'SET_LOADING':
      return { ...state, loading: action.payload };
      
    case 'SET_ERROR':
      return { ...state, error: action.payload };
      
    default:
      return state;
  }
};

export const usePluginState = () => {
  const [state, dispatch] = useReducer(pluginReducer, {
    resources: [],
    filters: {},
    pagination: { page: 1, perPage: 20, total: 0 },
    selectedItems: new Set(),
    loading: false,
    error: null,
  });
  
  const filteredResources = useMemo(() => {
    return state.resources.filter(resource => {
      if (state.filters.namespace && resource.metadata?.namespace !== state.filters.namespace) {
        return false;
      }
      
      if (state.filters.status && resource.status?.phase !== state.filters.status) {
        return false;
      }
      
      if (state.filters.search) {
        const searchLower = state.filters.search.toLowerCase();
        const name = resource.metadata?.name?.toLowerCase() || '';
        if (!name.includes(searchLower)) {
          return false;
        }
      }
      
      return true;
    });
  }, [state.resources, state.filters]);
  
  const paginatedResources = useMemo(() => {
    const start = (state.pagination.page - 1) * state.pagination.perPage;
    const end = start + state.pagination.perPage;
    return filteredResources.slice(start, end);
  }, [filteredResources, state.pagination.page, state.pagination.perPage]);
  
  return {
    state,
    dispatch,
    filteredResources,
    paginatedResources,
  };
};
```

## Error Handling and Resilience

### Circuit Breaker Pattern

```typescript
class CircuitBreaker {
  private failureCount = 0;
  private lastFailureTime: number | null = null;
  private state: 'CLOSED' | 'OPEN' | 'HALF_OPEN' = 'CLOSED';
  
  constructor(
    private threshold: number = 5,
    private timeout: number = 60000
  ) {}
  
  async execute<T>(operation: () => Promise<T>): Promise<T> {
    if (this.state === 'OPEN') {
      if (this.shouldAttemptReset()) {
        this.state = 'HALF_OPEN';
      } else {
        throw new Error('Circuit breaker is OPEN');
      }
    }
    
    try {
      const result = await operation();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }
  
  private onSuccess() {
    this.failureCount = 0;
    this.state = 'CLOSED';
  }
  
  private onFailure() {
    this.failureCount++;
    this.lastFailureTime = Date.now();
    
    if (this.failureCount >= this.threshold) {
      this.state = 'OPEN';
    }
  }
  
  private shouldAttemptReset(): boolean {
    return this.lastFailureTime !== null &&
           Date.now() - this.lastFailureTime >= this.timeout;
  }
}

// Usage in API calls
const apiCircuitBreaker = new CircuitBreaker(3, 30000);

const useResilientApi = () => {
  const callApi = useCallback(async <T>(operation: () => Promise<T>) => {
    try {
      return await apiCircuitBreaker.execute(operation);
    } catch (error) {
      console.error('API call failed:', error);
      throw error;
    }
  }, []);
  
  return { callApi };
};
```

### Graceful Degradation

```typescript
const ResilientComponent: React.FC = () => {
  const [resources, setResources] = useState<MyResource[]>([]);
  const [fallbackMode, setFallbackMode] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  useEffect(() => {
    const loadResources = async () => {
      try {
        // Primary data source
        const data = await fetchResourcesFromApi();
        setResources(data);
        setFallbackMode(false);
        setError(null);
      } catch (primaryError) {
        console.warn('Primary API failed, trying fallback:', primaryError);
        
        try {
          // Fallback to cached data or alternative source
          const fallbackData = await fetchFromCache() || [];
          setResources(fallbackData);
          setFallbackMode(true);
          setError('Using cached data - some information may be outdated');
        } catch (fallbackError) {
          console.error('Both primary and fallback failed:', fallbackError);
          setFallbackMode(true);
          setError('Unable to load resources');
        }
      }
    };
    
    loadResources();
  }, []);
  
  if (error && resources.length === 0) {
    return (
      <EmptyState>
        <EmptyStateIcon icon={ExclamationTriangleIcon} />
        <Title headingLevel="h4">Unable to load resources</Title>
        <EmptyStateBody>{error}</EmptyStateBody>
        <Button variant="primary" onClick={() => window.location.reload()}>
          Retry
        </Button>
      </EmptyState>
    );
  }
  
  return (
    <div>
      {fallbackMode && (
        <Alert variant="warning" title="Limited functionality" className="pf-u-mb-md">
          Some features may be unavailable. {error}
        </Alert>
      )}
      
      <ResourceList 
        resources={resources}
        readOnly={fallbackMode}
      />
    </div>
  );
};
```

## Testing Advanced Patterns

### Integration Testing for Complex Workflows

```typescript
// integration-tests/advanced-workflows.spec.ts
describe('Advanced Plugin Workflows', () => {
  beforeEach(() => {
    cy.login();
    cy.intercept('GET', '/api/kubernetes/apis/my-group.io/v1/myresources', 
      { fixture: 'resources.json' });
  });
  
  it('should handle bulk operations correctly', () => {
    cy.visit('/my-plugin/resources');
    
    // Select multiple resources
    cy.get('[data-test="resource-checkbox"]').first().click();
    cy.get('[data-test="resource-checkbox"]').eq(1).click();
    
    // Perform bulk action
    cy.get('[data-test="bulk-actions"]').click();
    cy.get('[data-test="bulk-delete"]').click();
    
    // Confirm bulk operation
    cy.get('[data-test="confirm-bulk-delete"]').click();
    
    // Verify operation completed
    cy.get('[data-test="success-alert"]').should('be.visible');
  });
  
  it('should handle error scenarios gracefully', () => {
    // Simulate API error
    cy.intercept('GET', '/api/kubernetes/apis/my-group.io/v1/myresources', 
      { statusCode: 500, body: { message: 'Server error' } });
    
    cy.visit('/my-plugin/resources');
    
    // Should show error state
    cy.get('[data-test="error-state"]').should('be.visible');
    cy.get('[data-test="retry-button"]').should('be.visible');
    
    // Test retry functionality
    cy.intercept('GET', '/api/kubernetes/apis/my-group.io/v1/myresources', 
      { fixture: 'resources.json' });
    cy.get('[data-test="retry-button"]').click();
    
    // Should recover and show data
    cy.get('[data-test="resource-list"]').should('be.visible');
  });
});
```

## Related Skills

- [openshift-console-plugin-setup](../openshift-console-plugin-setup/SKILL.md) - Project setup for advanced configurations
- [openshift-console-plugin-components](../openshift-console-plugin-components/SKILL.md) - Advanced component patterns
- [openshift-console-plugin-data](../openshift-console-plugin-data/SKILL.md) - Advanced data management
- [openshift-console-plugin-deployment](../openshift-console-plugin-deployment/SKILL.md) - Production deployment considerations
- [openshift-console-plugin-development](../openshift-console-plugin-development/SKILL.md) - Advanced testing strategies

## Advanced Development Checklist

- [ ] Implement code splitting for large components
- [ ] Optimize webpack bundle configuration
- [ ] Add performance monitoring and profiling
- [ ] Implement proper error boundaries and fallback UI
- [ ] Set up comprehensive security headers
- [ ] Validate and sanitize all user inputs
- [ ] Implement circuit breaker patterns for API calls
- [ ] Add caching strategies for improved performance
- [ ] Use virtual scrolling for large data sets
- [ ] Implement graceful degradation for offline scenarios
- [ ] Add comprehensive integration tests
- [ ] Monitor bundle size and performance metrics
- [ ] Implement advanced state management patterns
- [ ] Set up proper logging and error reporting
- [ ] Add feature flag support for experimental features