---
name: openshift-console-plugin-styling
description: UI design, PatternFly usage, and CSS best practices for OpenShift Console plugins
---

# OpenShift Console Plugin Styling

This skill covers UI design, PatternFly component usage, and CSS best practices for creating consistent, accessible, and theme-compatible OpenShift Console plugins.

## PatternFly First Approach

**⚠️ CRITICAL: Always prefer PatternFly components over custom implementations**

The OpenShift Console uses PatternFly as its design system. Using PatternFly components ensures consistency, accessibility, theming support, and reduces maintenance burden. Avoid creating custom components when PatternFly alternatives exist.

### Why Use PatternFly Components

1. **Consistency**: Matches OpenShift Console's look and feel
2. **Accessibility**: Built-in ARIA attributes and keyboard navigation
3. **Theming**: Automatic dark/light mode support
4. **Responsive**: Mobile and desktop optimized
5. **Maintenance**: Updates handled by PatternFly team
6. **Performance**: Optimized and tested components

## Core PatternFly Components for Console Plugins

### Dashboard and Layout Components
```typescript
import {
  Page,           // Main page wrapper
  PageSection,    // Content sections
  Card,          // Content cards
  CardTitle,     // Card headers
  CardBody,      // Card content
  Gallery,       // Responsive grid layout
  GalleryItem,   // Grid items
  Grid,          // Manual grid system
  GridItem,      // Grid cells
  Flex,          // Flexbox layout
  FlexItem,      // Flex children
  Stack,         // Vertical stacking
  StackItem      // Stack children
} from '@patternfly/react-core';

// Example: Dashboard with cards
const MyDashboard: React.FC = () => (
  <Page>
    <PageSection variant="light">
      <Gallery hasGutter>
        <GalleryItem>
          <Card>
            <CardTitle>Cluster Status</CardTitle>
            <CardBody>Content here</CardBody>
          </Card>
        </GalleryItem>
        <GalleryItem>
          <Card>
            <CardTitle>Resource Usage</CardTitle>
            <CardBody>More content</CardBody>
          </Card>
        </GalleryItem>
      </Gallery>
    </PageSection>
  </Page>
);
```

### Data Display Components
```typescript
import {
  Table,           // Data tables
  Thead,           // Table header
  Tbody,           // Table body
  Tr,              // Table rows
  Th,              // Header cells
  Td,              // Data cells
  DataList,        // Alternative to tables
  DataListItem,    // List items
  DescriptionList, // Key-value pairs
  Label,           // Status labels
  Badge,           // Count indicators
  Progress,        // Progress bars
  Spinner          // Loading indicators
} from '@patternfly/react-core';

// Example: Resource status display
const ResourceStatus: React.FC<{ resource }> = ({ resource }) => (
  <Card>
    <CardBody>
      <DescriptionList>
        <DescriptionListGroup>
          <DescriptionListTerm>Status</DescriptionListTerm>
          <DescriptionListDescription>
            <Label color={resource.status === 'Ready' ? 'green' : 'red'}>
              {resource.status}
            </Label>
          </DescriptionListDescription>
        </DescriptionListGroup>
        <DescriptionListGroup>
          <DescriptionListTerm>Progress</DescriptionListTerm>
          <DescriptionListDescription>
            <Progress value={resource.progress} />
          </DescriptionListDescription>
        </DescriptionListGroup>
      </DescriptionList>
    </CardBody>
  </Card>
);
```

### Navigation and Actions
```typescript
import {
  Tabs,            // Tab navigation
  Tab,             // Individual tabs
  TabTitleText,    // Tab labels
  Breadcrumb,      // Navigation breadcrumbs
  BreadcrumbItem,  // Breadcrumb links
  Button,          // Action buttons
  Dropdown,        // Action menus
  DropdownItem,    // Menu items
  KebabToggle,     // Three-dot menu
  Toolbar,         // Action toolbars
  ToolbarContent,  // Toolbar sections
  ToolbarGroup,    // Toolbar groups
  ToolbarItem      // Individual tools
} from '@patternfly/react-core';

// Example: Resource actions toolbar
const ResourceActions: React.FC = () => (
  <Toolbar>
    <ToolbarContent>
      <ToolbarGroup>
        <ToolbarItem>
          <Button variant="primary">Create</Button>
        </ToolbarItem>
        <ToolbarItem>
          <Dropdown
            toggle={<KebabToggle />}
            dropdownItems={[
              <DropdownItem key="edit">Edit</DropdownItem>,
              <DropdownItem key="delete">Delete</DropdownItem>
            ]}
          />
        </ToolbarItem>
      </ToolbarGroup>
    </ToolbarContent>
  </Toolbar>
);
```

### Forms and Input Components
```typescript
import {
  Form,            // Form wrapper
  FormGroup,       // Form sections
  TextInput,       // Text fields
  Select,          // Dropdowns
  SelectOption,    // Dropdown options
  Checkbox,        // Checkboxes
  Radio,           // Radio buttons
  Switch,          // Toggle switches
  FormHelperText,  // Help text
  Alert            // Validation messages
} from '@patternfly/react-core';

// Example: Configuration form
const ConfigForm: React.FC = () => (
  <Form>
    <FormGroup label="Resource Name" isRequired>
      <TextInput id="name" />
      <FormHelperText>Must be unique within namespace</FormHelperText>
    </FormGroup>
    <FormGroup label="Enable Feature">
      <Switch id="feature-toggle" />
    </FormGroup>
  </Form>
);
```

### Status and Feedback Components
```typescript
import {
  Alert,              // Notifications
  AlertGroup,         // Alert containers
  Banner,             // Page banners
  EmptyState,         // No data states
  EmptyStateBody,     // Empty state content
  EmptyStateIcon,     // Empty state icons
  Modal,              // Dialog modals
  ModalVariant,       // Modal types
  NotificationDrawer, // Notification panel
  Tooltip             // Help tooltips
} from '@patternfly/react-core';

// Example: Empty state for resource lists
const NoResourcesFound: React.FC = () => (
  <EmptyState>
    <EmptyStateIcon icon={CubesIcon} />
    <Title headingLevel="h4">No resources found</Title>
    <EmptyStateBody>
      Create your first resource to get started.
    </EmptyStateBody>
    <Button variant="primary">Create Resource</Button>
  </EmptyState>
);
```

## PatternFly vs Custom Components Decision Guide

| Use Case | Prefer PatternFly | Consider Custom |
|----------|-------------------|-----------------|
| Data tables | ✅ Table component | ❌ |
| Status displays | ✅ Label, Badge | ❌ |
| Forms | ✅ Form components | ❌ |
| Navigation | ✅ Tabs, Breadcrumb | ❌ |
| Cards/panels | ✅ Card component | ❌ |
| Buttons/actions | ✅ Button, Dropdown | ❌ |
| Loading states | ✅ Spinner, Progress | ❌ |
| Empty states | ✅ EmptyState | ❌ |
| Modals/dialogs | ✅ Modal | ❌ |
| Unique visualizations | Consider first | ✅ Charts, diagrams |
| Domain-specific widgets | Consider first | ✅ If no PF equivalent |

## Styling Best Practices

**⚠️ NEVER use inline styles - Always use CSS classes or PatternFly props**

Inline styles should be avoided in OpenShift Console plugins for several critical reasons:

### Why Avoid Inline Styles?
1. **Theming Breaks**: Inline styles override CSS custom properties, breaking dark/light theme switching
2. **Responsiveness**: Cannot use media queries or responsive design patterns
3. **Accessibility**: Harder to implement focus states, high contrast modes, and screen reader optimizations
4. **Maintenance**: Difficult to update styling across components
5. **Performance**: Inline styles prevent CSS caching and optimization
6. **Consistency**: Prevents using PatternFly design tokens and variables
7. **CSP Violations**: May violate Content Security Policy rules

### ✅ CORRECT Styling Approaches

#### CSS Classes with Plugin Prefixing
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

### ❌ WRONG - Avoid These Patterns
```typescript
// DON'T DO THIS - Inline styles break theming
const BadComponent: React.FC = () => (
  <div style={{ 
    padding: '16px',           // Use CSS classes instead
    backgroundColor: '#f0f0f0', // Breaks dark theme
    color: 'red'               // Use PatternFly color props
  }}>
    Content
  </div>
);

// DON'T DO THIS - Conditional inline styles
const AnotherBadComponent: React.FC = ({ isError }) => (
  <span style={{ 
    color: isError ? '#d73502' : '#28a745' // Use CSS classes + conditional className
  }}>
    Status
  </span>
);
```

## Component Styling - Correct Approaches

### Method 1: CSS Classes with Conditional Styling
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

interface MyComponentProps {
  status: 'running' | 'failed' | 'pending';
  isHighlighted?: boolean;
}

const MyComponent: React.FC<MyComponentProps> = ({ status, isHighlighted }) => {
  // Use conditional className instead of inline styles
  const containerClassName = [
    'my-console-plugin__status-card',
    isHighlighted && 'my-console-plugin__status-card--highlighted'
  ].filter(Boolean).join(' ');

  return (
    <Card className={containerClassName}>
      <CardTitle>Status Overview</CardTitle>
      <CardBody>
        <Flex>
          <FlexItem>
            <span className={`my-console-plugin__status my-console-plugin__status--${status}`}>
              {status}
            </span>
          </FlexItem>
          <FlexItem>
            {/* Use PatternFly color props when available */}
            <Label color={status === 'running' ? 'green' : status === 'failed' ? 'red' : 'grey'}>
              {status}
            </Label>
          </FlexItem>
        </Flex>
      </CardBody>
    </Card>
  );
};

export default MyComponent;
```

### Method 2: PatternFly Component Props
```typescript
import React from 'react';
import {
  Card,
  CardTitle,
  CardBody,
  Alert,
  Button,
  Flex,
  FlexItem
} from '@patternfly/react-core';

const MyAlertComponent: React.FC<{ hasError: boolean }> = ({ hasError }) => (
  <Card>
    <CardBody>
      {/* Use PatternFly variant props instead of inline styles */}
      <Alert 
        variant={hasError ? 'danger' : 'success'} 
        title={hasError ? 'Error occurred' : 'Success'}
      />
      <Flex>
        <FlexItem>
          {/* Use PatternFly size and variant props */}
          <Button 
            variant={hasError ? 'danger' : 'primary'}
            size="sm"
          >
            {hasError ? 'Retry' : 'Continue'}
          </Button>
        </FlexItem>
      </Flex>
    </CardBody>
  </Card>
);
```

### Method 3: CSS-in-JS Alternative (Use Sparingly)
```typescript
import React from 'react';
import { Card } from '@patternfly/react-core';

// If CSS-in-JS is absolutely necessary, use CSS custom properties
const MyDynamicComponent: React.FC<{ progress: number }> = ({ progress }) => {
  // Use CSS custom properties, not direct style values
  const cardStyle = {
    '--my-progress-width': `${progress}%`
  } as React.CSSProperties;

  return (
    <Card className="my-console-plugin__progress-card" style={cardStyle}>
      {/* Progress bar uses CSS custom property in stylesheet */}
      <div className="my-console-plugin__progress-bar" />
    </Card>
  );
};
```

## CSS File Organization

### Component CSS Structure
```css
/* MyComponent.css */

/* Main component styles */
.my-console-plugin__status-card {
  margin-bottom: var(--pf-v6-global-spacer-md);
  border-radius: var(--pf-v6-global-BorderRadius-md);
}

/* Modifier classes for state variations */
.my-console-plugin__status-card--highlighted {
  border: 2px solid var(--pf-v6-global-palette--blue-300);
  box-shadow: var(--pf-v6-global-box-shadow-md);
}

/* Status indicator styles */
.my-console-plugin__status {
  font-weight: var(--pf-v6-global-FontWeight-bold);
  padding: var(--pf-v6-global-spacer-xs);
  border-radius: var(--pf-v6-global-BorderRadius-sm);
}

.my-console-plugin__status--running {
  background-color: var(--pf-v6-global-palette--green-50);
  color: var(--pf-v6-global-palette--green-700);
}

.my-console-plugin__status--failed {
  background-color: var(--pf-v6-global-palette--red-50);
  color: var(--pf-v6-global-palette--red-700);
}

.my-console-plugin__status--pending {
  background-color: var(--pf-v6-global-palette--orange-50);
  color: var(--pf-v6-global-palette--orange-700);
}

/* CSS custom property approach for dynamic values */
.my-console-plugin__progress-card {
  position: relative;
  overflow: hidden;
}

.my-console-plugin__progress-bar {
  width: var(--my-progress-width);
  height: 4px;
  background-color: var(--pf-v6-global-palette--blue-300);
  transition: width 0.3s ease;
}

/* Responsive design using media queries */
@media (max-width: 768px) {
  .my-console-plugin__status-card {
    margin-bottom: var(--pf-v6-global-spacer-sm);
  }
  
  .my-console-plugin__status {
    font-size: var(--pf-v6-global-FontSize-sm);
  }
}

/* Dark theme considerations */
@media (prefers-color-scheme: dark) {
  .my-console-plugin__status-card--highlighted {
    border-color: var(--pf-v6-global-palette--blue-200);
  }
}
```

## Theme Compatibility

### Using CSS Custom Properties
```css
/* Always use PatternFly CSS variables for colors */
.my-plugin__primary-text {
  color: var(--pf-v6-global-Color-100);
}

.my-plugin__secondary-text {
  color: var(--pf-v6-global-Color-200);
}

.my-plugin__background {
  background-color: var(--pf-v6-global-BackgroundColor-100);
}

.my-plugin__border {
  border: 1px solid var(--pf-v6-global-BorderColor-100);
}

/* Status colors */
.my-plugin__success {
  color: var(--pf-v6-global-success-color-100);
}

.my-plugin__warning {
  color: var(--pf-v6-global-warning-color-100);
}

.my-plugin__danger {
  color: var(--pf-v6-global-danger-color-100);
}
```

### Responsive Design Patterns
```css
/* Mobile-first approach */
.my-plugin__card-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--pf-v6-global-spacer-md);
}

/* Tablet */
@media (min-width: 768px) {
  .my-plugin__card-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

/* Desktop */
@media (min-width: 1200px) {
  .my-plugin__card-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

/* Large screens */
@media (min-width: 1600px) {
  .my-plugin__card-grid {
    grid-template-columns: repeat(4, 1fr);
  }
}
```

## Accessibility in Styling

### Focus States
```css
/* Ensure visible focus indicators */
.my-plugin__interactive-element {
  border-radius: var(--pf-v6-global-BorderRadius-sm);
  transition: all 0.2s ease;
}

.my-plugin__interactive-element:focus {
  outline: 2px solid var(--pf-v6-global-palette--blue-300);
  outline-offset: 2px;
}

.my-plugin__interactive-element:focus:not(:focus-visible) {
  outline: none;
}

.my-plugin__interactive-element:focus-visible {
  outline: 2px solid var(--pf-v6-global-palette--blue-300);
  outline-offset: 2px;
}
```

### High Contrast Mode
```css
/* High contrast media query support */
@media (prefers-contrast: high) {
  .my-plugin__card {
    border: 2px solid;
  }
  
  .my-plugin__status--running {
    background-color: transparent;
    border: 2px solid var(--pf-v6-global-palette--green-500);
  }
}
```

## Performance Considerations

### CSS Loading Strategy
```typescript
// Lazy load CSS for large components
const LazyStyledComponent = React.lazy(async () => {
  // Import CSS
  await import('./LazyComponent.css');
  // Import component
  return import('./LazyComponent');
});
```

### CSS Optimization Tips
1. **Use CSS Custom Properties**: Better performance than CSS-in-JS
2. **Minimize CSS Specificity**: Use single classes when possible
3. **Avoid Deep Nesting**: Keep CSS selectors shallow
4. **Group Related Styles**: Organize CSS logically
5. **Use PatternFly Utilities**: Leverage existing utility classes

## Related Skills

- [openshift-console-plugin-components](../openshift-console-plugin-components/SKILL.md) - React component development patterns
- [openshift-console-plugin-setup](../openshift-console-plugin-setup/SKILL.md) - Project setup and PatternFly versions
- [openshift-console-plugin-development](../openshift-console-plugin-development/SKILL.md) - Linting CSS and styling workflow
- [openshift-console-plugin-advanced](../openshift-console-plugin-advanced/SKILL.md) - Performance optimization for styles

## Styling Checklist

- [ ] Use PatternFly components instead of custom implementations
- [ ] Never use inline styles - use CSS classes or PatternFly props
- [ ] Prefix all custom CSS classes with plugin name
- [ ] Use PatternFly CSS variables instead of hex colors
- [ ] Implement responsive design with media queries
- [ ] Add proper focus states for accessibility
- [ ] Test in both light and dark themes
- [ ] Use semantic color variables (success, warning, danger)
- [ ] Optimize CSS for performance
- [ ] Follow mobile-first design approach