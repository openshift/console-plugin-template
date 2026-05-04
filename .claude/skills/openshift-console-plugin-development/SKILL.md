---
name: openshift-console-plugin-development
description: Development workflow, testing, linting, and debugging for OpenShift Console plugins
---

# OpenShift Console Plugin Development

This skill covers the complete development workflow for OpenShift Console plugins, including local development setup, testing strategies, code quality tools, and debugging techniques.

## Development Workflow

### Plugin Testing Requirements

**⚠️ IMPORTANT: Plugin Testing Requirements**

To test your console plugin, you MUST run both the development server AND the OpenShift Console container. Running only the development server (`npm run start`) is insufficient for testing because:

1. **Plugin Loading**: The console must load your plugin via module federation
2. **Authentication**: Console APIs require proper authentication context
3. **Extension Points**: Navigation items, routes, and other extensions only work within the full console
4. **K8s API Access**: Resource operations require the console's proxy to the cluster APIs

### Complete Development Setup
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

### Testing Workflow
```bash
# After making changes to your plugin:
# 1. Webpack dev server automatically rebuilds (from step 3)
# 2. Refresh browser at http://localhost:9000 to see changes
# 3. Check browser console for any plugin loading errors

# Run automated tests
npm run test                    # Unit tests
npm run test-cypress-headless   # E2E tests

# Code quality checks (REQUIRED before committing)
npm run lint                    # ESLint + Stylelint with auto-fix
```

## Code Quality and Linting

### Pre-Commit Checklist

**⚠️ ALWAYS run the linter before committing changes**

**Code Quality First**: Always run `yarn lint` before testing and committing. This catches style issues, potential bugs, and accessibility violations before they reach testing or production.

```bash
# Essential pre-commit workflow:
# 1. Run linter (fixes most issues automatically)
yarn lint

# 2. Review any remaining linter errors that couldn't be auto-fixed
# 3. Fix any TypeScript compilation errors
yarn tsc --noEmit

# 4. Test your changes work in the browser
# 5. Stage and commit your changes
git add .
git commit -m "Your commit message"
```

### Why Lint Before Committing?
- **Consistency**: Maintains consistent code style across the project
- **Quality**: Catches potential bugs and code issues early
- **CI/CD**: Prevents build failures in continuous integration
- **Collaboration**: Makes code reviews easier and more focused
- **Accessibility**: ESLint rules help catch accessibility issues
- **Performance**: Identifies potential performance anti-patterns

### What the Linter Checks
- Code formatting (Prettier)
- JavaScript/TypeScript best practices (ESLint)
- CSS style consistency (Stylelint)
- Accessibility violations
- Potential security issues
- Import/export consistency

## Testing Strategies

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

  it('renders page title correctly', () => {
    renderWithI18n(<MyPage />);
    expect(screen.getByRole('heading', { name: /my page/i })).toBeInTheDocument();
  });

  it('displays content when loaded', () => {
    renderWithI18n(<MyPage />);
    expect(screen.getByText(/page content/i)).toBeInTheDocument();
  });
});
```

### Testing Data Hooks
```typescript
// src/hooks/__tests__/useMyResources.test.tsx
import { renderHook } from '@testing-library/react';
import { useK8sWatchResource } from '@openshift-console/dynamic-plugin-sdk';
import { useMyResources } from '../useMyResources';

// Mock the SDK hook
jest.mock('@openshift-console/dynamic-plugin-sdk', () => ({
  useK8sWatchResource: jest.fn(),
}));

const mockUseK8sWatchResource = useK8sWatchResource as jest.MockedFunction<typeof useK8sWatchResource>;

describe('useMyResources', () => {
  it('returns resources when loaded', () => {
    const mockResources = [
      { metadata: { name: 'test-resource' } }
    ];
    
    mockUseK8sWatchResource.mockReturnValue([mockResources, true, undefined]);

    const { result } = renderHook(() => useMyResources('test-namespace'));

    expect(result.current.resources).toEqual(mockResources);
    expect(result.current.loaded).toBe(true);
    expect(result.current.loadError).toBeUndefined();
  });

  it('handles loading error', () => {
    const mockError = new Error('Failed to load');
    mockUseK8sWatchResource.mockReturnValue([[], false, mockError]);

    const { result } = renderHook(() => useMyResources('test-namespace'));

    expect(result.current.resources).toEqual([]);
    expect(result.current.loaded).toBe(false);
    expect(result.current.loadError).toBe(mockError);
  });
});
```

### Integration Testing with Cypress

```typescript
// integration-tests/my-plugin.spec.ts
describe('My Console Plugin', () => {
  beforeEach(() => {
    cy.login();
    cy.visit('/my-plugin');
  });

  it('should display plugin navigation', () => {
    cy.get('[data-test="nav-item-my-plugin"]').should('be.visible');
  });

  it('should load plugin page', () => {
    cy.get('[data-test="nav-item-my-plugin"]').click();
    cy.get('[data-test="my-plugin-page"]').should('be.visible');
    cy.get('h1').should('contain', 'My Plugin');
  });

  it('should create a new resource', () => {
    cy.get('[data-test="create-resource-button"]').click();
    cy.get('[data-test="resource-name-input"]').type('test-resource');
    cy.get('[data-test="create-button"]').click();
    
    cy.get('[data-test="resource-list"]').should('contain', 'test-resource');
  });

  it('should handle error states', () => {
    cy.intercept('GET', '/api/kubernetes/apis/my-group.io/v1/namespaces/*/myresources', {
      statusCode: 500,
      body: { message: 'Server error' }
    });

    cy.visit('/my-plugin/resources');
    cy.get('[data-test="error-alert"]').should('be.visible');
    cy.get('[data-test="error-alert"]').should('contain', 'Error loading resources');
  });
});
```

## Debugging Techniques

### Browser DevTools Debugging

```typescript
// Add debugging helpers in development
const MyComponent: React.FC = () => {
  const [resources, loaded, loadError] = useMyResources();

  // Debug logging in development
  React.useEffect(() => {
    if (process.env.NODE_ENV === 'development') {
      console.log('MyComponent render:', { resources, loaded, loadError });
    }
  }, [resources, loaded, loadError]);

  // Debug breakpoint
  if (process.env.NODE_ENV === 'development' && resources.length > 0) {
    debugger; // Will pause in browser devtools
  }

  return <div>Component content</div>;
};
```

### Console Extension Debugging
```typescript
// Debug extension loading
const MyPage: React.FC = () => {
  React.useEffect(() => {
    if (process.env.NODE_ENV === 'development') {
      console.log('Plugin extension loaded:', {
        pathname: window.location.pathname,
        extensions: window.SERVER_FLAGS?.consolePlugins
      });
    }
  }, []);

  return <Page>...</Page>;
};
```

### Network Request Debugging
```typescript
// Debug API calls
const debugApiCall = (url: string, options?: RequestInit) => {
  if (process.env.NODE_ENV === 'development') {
    console.log('API Call:', { url, options });
  }
  return consoleFetch(url, options);
};

// Use in API operations
const createResource = async (data: MyResource) => {
  try {
    const response = await debugApiCall('/api/kubernetes/apis/my-group.io/v1/namespaces/default/myresources', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    return response.json();
  } catch (error) {
    console.error('Create resource failed:', error);
    throw error;
  }
};
```

## Troubleshooting Plugin Loading

### Common Issues and Solutions

#### Plugin Not Loading
```bash
# Check webpack dev server is running
curl http://localhost:9001/plugin-entry.js

# Check console container logs
docker logs $(docker ps --filter "ancestor=quay.io/openshift/console" --format "{{.ID}}")

# Verify plugin registration
oc get consolePlugin my-plugin -o yaml
```

#### Extension Points Not Working
1. **Check console-extensions.json matches exposedModules**:
```json
// console-extensions.json
"component": { "$codeRef": "MyPage" }

// package.json
"exposedModules": {
  "MyPage": "./components/MyPage"  // Must match exactly
}
```

2. **Verify component exports**:
```typescript
// Component must be default export
const MyPage: React.FC = () => { ... };
export default MyPage; // Required for $codeRef
```

#### Module Federation Issues
```typescript
// Check webpack.config.ts
const config: webpack.Configuration = {
  plugins: [
    new ModuleFederationPlugin({
      name: 'my-plugin',
      filename: 'plugin-entry.js',
      exposes: {
        './plugin': './src/plugin.ts', // Entry point
        './MyPage': './src/components/MyPage', // Components
      },
    }),
  ],
};
```

### Development Scripts

Common development commands:
```json
{
  "scripts": {
    "start": "webpack serve --config webpack.config.ts",
    "start-console": "./scripts/start-console.sh",
    "build": "webpack --mode production",
    "test": "jest",
    "test:watch": "jest --watch",
    "test-cypress": "cypress open",
    "test-cypress-headless": "cypress run",
    "lint": "eslint src --ext .ts,.tsx --fix && stylelint 'src/**/*.css' --fix",
    "lint:check": "eslint src --ext .ts,.tsx && stylelint 'src/**/*.css'",
    "tsc": "tsc --noEmit",
    "i18n": "i18next-scanner --config i18next-scanner.config.js"
  }
}
```

## Performance Monitoring

### Bundle Analysis
```bash
# Analyze bundle size
npm run build
npx webpack-bundle-analyzer dist/

# Check for large dependencies
npm install -g webpack-bundle-analyzer
webpack-bundle-analyzer dist/main.js
```

### Runtime Performance
```typescript
// Performance monitoring in development
const withPerformanceMonitoring = <P extends object>(
  WrappedComponent: React.ComponentType<P>
) => {
  return (props: P) => {
    React.useEffect(() => {
      if (process.env.NODE_ENV === 'development') {
        const startTime = performance.now();
        return () => {
          const endTime = performance.now();
          console.log(`${WrappedComponent.name} render time: ${endTime - startTime}ms`);
        };
      }
    });

    return <WrappedComponent {...props} />;
  };
};

// Usage
export default withPerformanceMonitoring(MyExpensiveComponent);
```

## Error Handling and Monitoring

### Error Boundaries
```typescript
// Global error boundary for plugin
class PluginErrorBoundary extends React.Component<
  React.PropsWithChildren<{}>,
  { hasError: boolean; error?: Error }
> {
  constructor(props: React.PropsWithChildren<{}>) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('Plugin error:', error, errorInfo);
    
    // Send error to monitoring service in production
    if (process.env.NODE_ENV === 'production') {
      // sendErrorToMonitoring(error, errorInfo);
    }
  }

  render() {
    if (this.state.hasError) {
      return (
        <Alert 
          variant="danger" 
          title="Plugin Error"
          actionLinks={
            <Button variant="link" onClick={() => window.location.reload()}>
              Reload Page
            </Button>
          }
        >
          Something went wrong in the plugin. Please try reloading the page.
        </Alert>
      );
    }

    return this.props.children;
  }
}
```

### Development vs Production Configurations

```typescript
// Environment-specific configurations
const isDevelopment = process.env.NODE_ENV === 'development';

export const config = {
  // API endpoints
  apiBaseUrl: isDevelopment 
    ? 'http://localhost:8080/api' 
    : '/api',
    
  // Logging level
  logLevel: isDevelopment ? 'debug' : 'error',
  
  // Debug features
  enableDebugPanel: isDevelopment,
  
  // Performance monitoring
  enablePerformanceMonitoring: isDevelopment,
  
  // Error reporting
  enableErrorReporting: !isDevelopment,
};
```

## Related Skills

- [openshift-console-plugin-setup](../openshift-console-plugin-setup/SKILL.md) - Project setup and dependencies
- [openshift-console-plugin-components](../openshift-console-plugin-components/SKILL.md) - Component testing patterns
- [openshift-console-plugin-data](../openshift-console-plugin-data/SKILL.md) - Testing data hooks and operations
- [openshift-console-plugin-deployment](../openshift-console-plugin-deployment/SKILL.md) - Build and deployment workflow

## Development Checklist

- [ ] Set up local development with both dev server and console container
- [ ] Configure linting and run before all commits
- [ ] Write unit tests for components and hooks
- [ ] Add integration tests for critical user flows
- [ ] Set up error boundaries for error handling
- [ ] Configure debugging tools and logging
- [ ] Monitor bundle size and performance
- [ ] Test plugin loading and extension points
- [ ] Verify authentication and API access
- [ ] Test in different browser environments
- [ ] Check accessibility with screen readers
- [ ] Validate i18n translations work correctly

## Common Development Commands

```bash
# Start development environment
npm run start              # Plugin dev server
npm run start-console      # Console container
npm test                   # Run unit tests  
npm run test:watch         # Watch mode for tests
npm run test-cypress       # Integration tests
npm run lint               # Code quality checks
npm run build              # Production build
npm run i18n               # Update translations

# Debugging
npm run lint:check         # Check without fixes
npm run tsc                # TypeScript check
npx webpack-bundle-analyzer dist/  # Analyze bundle

# Cleanup
rm -rf node_modules dist   # Clean install
npm ci                     # Fresh install
```