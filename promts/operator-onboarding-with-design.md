
# Add a New Operator to OpenShift Console Plugin with Custom Design Integration

Extends the base operator-onboarding workflow with **design-first UI** from Figma, Google Stitch, or custom design systems.

## Purpose

This prompt combines K8s operator dashboard generation with custom UI/UX specifications. It:
- Retains **all functional logic** from operator-onboarding.md (CRD scanning, table generation, inspect pages)
- Integrates **design code** (Figma exports, Google Stitch components, Tailwind configs, or custom CSS)
- Maps design tokens to **PatternFly-compatible** variables while maintaining console plugin constraints

## When to Use This vs. Standard operator-onboarding.md

| Use Standard | Use Design-Integrated |
|--------------|----------------------|
| Default PatternFly look is acceptable | Custom brand/design system required |
| Quick operator dashboard | Design specs from Figma/Stitch/Sketch |
| Standard enterprise UI | Custom color palettes, typography, spacing |
| Minimal styling customization | Design handoff includes code exports |

---

## Prerequisites

### 1. Standard Operator Inputs (from operator-onboarding.md)
- Operator API resources verified via `oc api-resources`
- CRD metadata (group, version, kind, plural, namespaced)
- Optional: relationships, fixed namespace, column overrides

### 2. Design Inputs (NEW - Required)

Provide **one or more** of the following:

#### Option A: Figma Code Export
```
- Figma component code (HTML/CSS or React from Figma Dev Mode)
- Design tokens JSON (colors, typography, spacing)
- Component hierarchy/structure
```

#### Option B: Google Stitch Code
```
- Stitch component library code
- Material Design tokens or custom theme
- Component templates
```

#### Option C: Custom Design System
```
- CSS framework code (Tailwind config, Bootstrap theme, custom CSS)
- Typography specifications
- Color palette definitions
- Spacing/grid system
- Component design patterns
```

#### Option D: Design Handoff Package
```
- Style guide PDF/URL with specifications
- Asset exports (SVG icons, fonts)
- Responsive breakpoints
- Component states (hover, active, disabled)
```

**Critical:** Provide actual code/specifications, not just references. The AI needs concrete values to map.

---

## Mandatory Three-Phase Workflow

This document defines **three phases in one task**. **Do not stop after Phase 1 or Phase 2.**

| Phase | Scope | Gate |
|-------|--------|------|
| **Phase 1** | **Design System Analysis & Mapping** | Design tokens mapped to PatternFly variables |
| **Phase 2** | **Operator Dashboard Implementation** with custom design (Steps 0–14) | `yarn build-dev` and `yarn lint` succeed |
| **Phase 3** | **Unit Tests** for operator components and design system integration | `yarn test` and `yarn lint` succeed |

**Rules for agents:**

1. **Phase 1** must complete FIRST — analyze design code, extract tokens, create mapping document.
2. **Phase 2** uses the design mapping to generate styled components while maintaining K8s functionality.
3. **Phase 3** adds tests after implementation succeeds.
4. All phases must complete in **one session** — do not wait for separate prompts.
5. The task is **complete** only when **all three** phases pass their gates.

---

## End Goal

**Functional Requirements (identical to operator-onboarding.md):**
- ✅ Operator dashboard at `/<operator-short-name>` with K8s resource tables
- ✅ Per-row Inspect and Delete actions
- ✅ ResourceInspect detail pages with Metadata/Labels/Spec/Status/Events
- ✅ Sidebar navigation under Plugins
- ✅ Optional: expandable rows for parent-child relationships
- ✅ RBAC, i18n, validation

**Design Requirements (NEW):**
- ✅ **Custom color palette** applied via mapped PatternFly variables
- ✅ **Custom typography** (font families, sizes, weights) from design specs
- ✅ **Custom spacing system** matching design grid/tokens
- ✅ **Component hierarchy** from design preserved in React structure
- ✅ **Responsive behavior** per design breakpoints
- ✅ **Design system documentation** generated (design-to-code mapping)
- ✅ **No constraint violations** — all PatternFly/console plugin rules maintained

---

## Critical Constraints (Design Integration)

### Must Maintain from operator-onboarding.md:
1. ✅ **PatternFly CSS variables only** — no direct hex colors in code
2. ✅ **Plugin-prefixed classes** (`console-plugin-template__`)
3. ✅ **No OpenShift console classes** (`co-m-*`, `.pf-*` structure)
4. ✅ **React Router for navigation** (no `<a href>`)
5. ✅ **useK8sModel for operator detection** (not consoleFetchJSON)
6. ✅ **ResourceTable/ResourceInspect patterns** maintained

### New Design Constraints:
1. ✅ **Map design colors to PatternFly semantic variables** (not raw hex)
   - Example: Figma `#1E40AF` (blue-800) → `var(--pf-v6-global-palette--blue-800)`
2. ✅ **Override PatternFly variables via CSS custom properties** (not inline styles)
3. ✅ **Preserve PatternFly component API** (props, variants) while restyling
4. ✅ **Document all design deviations** from PatternFly defaults
5. ✅ **Maintain dark mode compatibility** (design must provide dark variants)
6. ✅ **Respect console plugin theming** (variables can be overridden by console)

---

## Prompt Template (copy, fill, run)

```text
Add a new operator to this OpenShift console plugin with custom design integration: [OPERATOR_NAME].

--- PART 1: OPERATOR INPUTS (Standard) ---

1) Detect operator using model (pick ONE primary resource for detection):
   - group: [e.g. myoperator.io]
   - version: [e.g. v1]
   - kind: [e.g. MyResource]

2) Resource kinds to expose (repeat block for each):
   - group: [e.g. myoperator.io]
   - version: [e.g. v1]
   - kind: [e.g. MyResource]
   - plural: [e.g. myresources]
   - namespaced: [true/false]
   - displayName: [e.g. My Resources]

3) Optional fixed namespace: [NAMESPACE or (none)]

4) Optional column overrides: [none] or per-resource list

5) Optional relationships (one-to-many): [none] or define parent-child relationships

6) API group verification (REQUIRED - paste output):
   ```bash
   oc api-resources | grep -i <operator-keyword>
   ```
   Paste full output here: [PASTE OUTPUT]

--- PART 2: DESIGN INPUTS (NEW - Required) ---

7) Design Source: [Figma / Google Stitch / Tailwind / Custom CSS / Style Guide]

8) Design Code/Specifications:
   Paste complete design code below. Include:
   - Color palette (with hex values or design token names)
   - Typography (font families, sizes, weights, line heights)
   - Spacing system (margin/padding scale)
   - Component styles (buttons, cards, tables, inputs)
   - Responsive breakpoints (if applicable)
   - Dark mode variants (if applicable)

   [PASTE DESIGN CODE HERE - can be CSS, JSON, React components, or structured specs]

   Example formats accepted:
   
   **Figma Design Tokens (JSON):**
   ```json
   {
     "colors": {
       "primary": "#1E40AF",
       "secondary": "#64748B",
       "success": "#10B981",
       "danger": "#EF4444"
     },
     "typography": {
       "heading1": { "size": "32px", "weight": 700, "lineHeight": 1.2 },
       "body": { "size": "14px", "weight": 400, "lineHeight": 1.5 }
     },
     "spacing": {
       "xs": "4px",
       "sm": "8px",
       "md": "16px",
       "lg": "24px",
       "xl": "32px"
     }
   }
   ```

   **OR Tailwind Config:**
   ```js
   module.exports = {
     theme: {
       colors: {
         brand: { primary: '#1E40AF', secondary: '#64748B' }
       },
       fontFamily: { sans: ['Inter', 'system-ui'] },
       spacing: { /* scale */ }
     }
   }
   ```

   **OR CSS Custom Properties:**
   ```css
   :root {
     --color-primary: #1E40AF;
     --font-heading: 'Inter', sans-serif;
     --spacing-unit: 8px;
   }
   ```

   **OR Figma Component Code (React/HTML):**
   ```jsx
   // Paste exported component code from Figma Dev Mode
   ```

9) Design Priority Areas (rank what matters most):
   - [ ] Color palette (branding)
   - [ ] Typography (fonts, hierarchy)
   - [ ] Spacing/Layout (grid, whitespace)
   - [ ] Component styling (buttons, cards, tables)
   - [ ] Responsive behavior
   - [ ] Animations/Transitions
   
   Priority order: [e.g., "1. Color, 2. Typography, 3. Spacing"]

10) Design Constraints/Preferences:
    - Must support dark mode: [yes/no]
    - Font loading strategy: [Google Fonts / Self-hosted / System fonts]
    - Browser support: [Modern evergreen / IE11 / Specific versions]
    - Accessibility requirements: [WCAG 2.1 AA / AAA / Custom]

--- EXECUTION INSTRUCTIONS ---

Follow the three-phase implementation workflow in this document exactly.

Phase 1: Analyze design code, extract design tokens, create PatternFly mapping.
Phase 2: Implement operator dashboard with mapped design system.
Phase 3: Add unit tests covering both K8s logic and design system application.

Start implementation immediately. Do not ask for confirmation.

If any operator input (fields 1-6) is missing EXCEPT field 6, infer from upstream CRD docs.
Field 6 (API verification) must NOT be inferred — obtain from actual cluster.

If design inputs (fields 7-10) are incomplete, request clarification BEFORE proceeding.
Do NOT infer design values — incorrect colors/spacing break branding.

All three phases must complete in this single run. Report validation for all phases in final summary.
```

---

## Phase 1: Design System Analysis & Mapping

**Objective:** Transform design code into PatternFly-compatible CSS variables and component patterns.

### Step 1.1: Parse Design Input

Analyze the provided design code and extract:

1. **Color Palette**
   - Primary, secondary, semantic colors (success, danger, warning, info)
   - Neutral grays for backgrounds, borders, text
   - Interactive states (hover, active, disabled, focus)
   - Dark mode variants (if provided)

2. **Typography System**
   - Font families (heading, body, monospace)
   - Font sizes (h1-h6, body, small, etc.)
   - Font weights (normal, medium, semibold, bold)
   - Line heights
   - Letter spacing (if specified)

3. **Spacing Scale**
   - Base unit (e.g., 4px, 8px)
   - Spacing tokens (xs, sm, md, lg, xl, 2xl, etc.)
   - Padding/margin values for components

4. **Component Patterns**
   - Button styles (variants, sizes, states)
   - Card/Panel designs (borders, shadows, backgrounds)
   - Table styling (headers, rows, borders, hover)
   - Input/Form field appearance
   - Navigation elements

5. **Layout/Grid**
   - Container max-widths
   - Responsive breakpoints
   - Grid/Flexbox patterns

### Step 1.2: Create PatternFly Variable Mapping

Generate a mapping document: `src/design-system/design-mapping.md`

```markdown
# Design System to PatternFly Mapping

## Color Palette Mapping

| Design Token | Design Value | PatternFly Variable | Override Value | Notes |
|--------------|-------------|---------------------|----------------|-------|
| primary | #1E40AF | --pf-v6-global--palette--blue-700 | #1E40AF | Exact match |
| secondary | #64748B | --pf-v6-global--palette--gray-500 | #64748B | Custom gray |
| success | #10B981 | --pf-v6-global--palette--green-500 | #10B981 | Brighter green |
| danger | #EF4444 | --pf-v6-global--palette--red-500 | #EF4444 | Matches danger |
| bg-primary | #FFFFFF | --pf-t--global--background--color--primary--default | #FFFFFF | Light mode |
| bg-secondary | #F8FAFC | --pf-t--global--background--color--secondary--default | #F8FAFC | Subtle gray |

## Typography Mapping

| Design Token | Design Value | PatternFly Variable | Override Value | Notes |
|--------------|-------------|---------------------|----------------|-------|
| font-heading | 'Inter', sans-serif | --pf-v6-global--FontFamily--heading | 'Inter', sans-serif | Custom font |
| font-body | 'Inter', sans-serif | --pf-v6-global--FontFamily--text | 'Inter', sans-serif | Same as heading |
| font-size-h1 | 32px | --pf-v6-global--FontSize--4xl | 32px | Matches design |
| font-weight-bold | 700 | --pf-v6-global--FontWeight--bold | 700 | Standard bold |

## Spacing Mapping

| Design Token | Design Value | PatternFly Variable | Override Value | Notes |
|--------------|-------------|---------------------|----------------|-------|
| spacing-xs | 4px | --pf-t--global--spacer--xs | 4px | Tight spacing |
| spacing-sm | 8px | --pf-t--global--spacer--sm | 8px | Small gaps |
| spacing-md | 16px | --pf-t--global--spacer--md | 16px | Default spacing |
| spacing-lg | 24px | --pf-t--global--spacer--lg | 24px | Section spacing |
| spacing-xl | 32px | --pf-t--global--spacer--xl | 32px | Large gaps |

## Component Overrides

### Buttons
- Primary button: Use design primary color via mapped variable
- Danger button: Use design danger color
- Border radius: [value from design or PatternFly default]

### Cards
- Background: [mapped bg variable]
- Border: [color and width]
- Shadow: [none | subtle | medium]
- Padding: [mapped spacing]

### Tables
- Header background: [mapped color]
- Row hover: [mapped hover state]
- Border color: [mapped border color]
- Cell padding: [mapped spacing]

## Dark Mode Mapping (if applicable)

| Design Token | Light Value | Dark Value | PatternFly Dark Variable |
|--------------|-------------|-----------|-------------------------|
| bg-primary | #FFFFFF | #1E1E1E | --pf-t--global--background--color--primary--default |
| text-primary | #1F2937 | #F9FAFB | --pf-t--global--text--color--default |

## Font Loading

Strategy: [Google Fonts / Self-hosted / System fonts]
Implementation: [CSS @import / <link> tag / Font files in /assets]

## Accessibility Notes

- Contrast ratios verified: [yes/no]
- Focus indicators: [design spec or PatternFly default]
- ARIA labels: [maintained from PatternFly components]
```

### Step 1.3: Generate CSS Variable Overrides

Create: `src/design-system/<operator-short-name>-theme.css`

```css
/**
 * Design System Theme Overrides for [Operator Name]
 * 
 * This file maps custom design tokens to PatternFly CSS variables.
 * DO NOT use hex colors directly in components — reference these variables.
 */

/* ========================================
   COLOR PALETTE
   ======================================== */

:root {
  /* Primary Brand Colors */
  --console-plugin-template--color-primary: #1E40AF;
  --console-plugin-template--color-secondary: #64748B;
  
  /* Semantic Colors */
  --console-plugin-template--color-success: #10B981;
  --console-plugin-template--color-danger: #EF4444;
  --console-plugin-template--color-warning: #F59E0B;
  --console-plugin-template--color-info: #3B82F6;
  
  /* Neutral Palette */
  --console-plugin-template--color-gray-50: #F9FAFB;
  --console-plugin-template--color-gray-100: #F3F4F6;
  --console-plugin-template--color-gray-500: #6B7280;
  --console-plugin-template--color-gray-900: #111827;
  
  /* Background Colors */
  --console-plugin-template--bg-primary: #FFFFFF;
  --console-plugin-template--bg-secondary: #F8FAFC;
  
  /* Text Colors */
  --console-plugin-template--text-primary: #1F2937;
  --console-plugin-template--text-secondary: #6B7280;
  
  /* Border Colors */
  --console-plugin-template--border-default: #E5E7EB;
  --console-plugin-template--border-hover: #D1D5DB;
}

/* Dark Mode Overrides (if design provides dark variants) */
@media (prefers-color-scheme: dark) {
  :root {
    --console-plugin-template--bg-primary: #1E1E1E;
    --console-plugin-template--bg-secondary: #2D2D2D;
    --console-plugin-template--text-primary: #F9FAFB;
    --console-plugin-template--text-secondary: #D1D5DB;
    --console-plugin-template--border-default: #374151;
  }
}

/* ========================================
   TYPOGRAPHY
   ======================================== */

:root {
  /* Font Families (load fonts in index.html or via @import) */
  --console-plugin-template--font-heading: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  --console-plugin-template--font-body: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  --console-plugin-template--font-mono: 'Roboto Mono', 'Courier New', monospace;
  
  /* Font Sizes */
  --console-plugin-template--font-size-xs: 12px;
  --console-plugin-template--font-size-sm: 14px;
  --console-plugin-template--font-size-md: 16px;
  --console-plugin-template--font-size-lg: 18px;
  --console-plugin-template--font-size-xl: 20px;
  --console-plugin-template--font-size-2xl: 24px;
  --console-plugin-template--font-size-3xl: 30px;
  --console-plugin-template--font-size-4xl: 36px;
  
  /* Font Weights */
  --console-plugin-template--font-weight-normal: 400;
  --console-plugin-template--font-weight-medium: 500;
  --console-plugin-template--font-weight-semibold: 600;
  --console-plugin-template--font-weight-bold: 700;
  
  /* Line Heights */
  --console-plugin-template--line-height-tight: 1.2;
  --console-plugin-template--line-height-normal: 1.5;
  --console-plugin-template--line-height-relaxed: 1.75;
}

/* ========================================
   SPACING
   ======================================== */

:root {
  /* Spacing Scale (matches design system) */
  --console-plugin-template--spacing-xs: 4px;
  --console-plugin-template--spacing-sm: 8px;
  --console-plugin-template--spacing-md: 16px;
  --console-plugin-template--spacing-lg: 24px;
  --console-plugin-template--spacing-xl: 32px;
  --console-plugin-template--spacing-2xl: 48px;
  --console-plugin-template--spacing-3xl: 64px;
}

/* ========================================
   COMPONENT TOKENS
   ======================================== */

:root {
  /* Border Radius */
  --console-plugin-template--border-radius-sm: 4px;
  --console-plugin-template--border-radius-md: 6px;
  --console-plugin-template--border-radius-lg: 8px;
  
  /* Shadows */
  --console-plugin-template--shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  --console-plugin-template--shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  --console-plugin-template--shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  
  /* Transitions */
  --console-plugin-template--transition-fast: 150ms ease-in-out;
  --console-plugin-template--transition-base: 200ms ease-in-out;
  --console-plugin-template--transition-slow: 300ms ease-in-out;
}

/* ========================================
   PATTERNFLY VARIABLE OVERRIDES
   Map custom tokens to PatternFly globals
   ======================================== */

:root {
  /* Override PatternFly colors with design system colors */
  --pf-v6-global--palette--blue-700: var(--console-plugin-template--color-primary);
  --pf-v6-global--palette--green-500: var(--console-plugin-template--color-success);
  --pf-v6-global--palette--red-500: var(--console-plugin-template--color-danger);
  
  /* Override typography */
  --pf-v6-global--FontFamily--heading: var(--console-plugin-template--font-heading);
  --pf-v6-global--FontFamily--text: var(--console-plugin-template--font-body);
  
  /* Override spacing (use with caution - may affect all PatternFly components) */
  /* --pf-t--global--spacer--md: var(--console-plugin-template--spacing-md); */
}
```

### Step 1.4: Validate Design Mapping

**Phase 1 Gate Checklist:**
- [ ] All design colors mapped to CSS variables (no raw hex in mapping)
- [ ] Typography tokens defined (fonts, sizes, weights)
- [ ] Spacing scale matches design system
- [ ] Component overrides documented
- [ ] Dark mode variants addressed (or documented as N/A)
- [ ] Font loading strategy determined
- [ ] `design-mapping.md` created
- [ ] `<operator-short-name>-theme.css` created
- [ ] No PatternFly constraint violations introduced

---

## Phase 2: Operator Dashboard Implementation with Custom Design

**Objective:** Build the operator dashboard using standard operator-onboarding.md steps, applying the design system from Phase 1.

### All Standard Steps from operator-onboarding.md Apply

Follow **Steps 0-13** from operator-onboarding.md exactly:
- Step 0: Verify API groups on cluster
- Step 1: Directories
- Step 2: useOperatorDetection hook
- Step 3: CRD models and TypeScript interfaces
- Step 4: Events mapping
- Step 5: OperatorNotInstalled component
- Step 6: Table components
- Step 6b: Expandable rows (if relationships defined)
- Step 7: CSS (see modifications below)
- Step 7b: Optional overview dashboard
- Step 8: Operator page component
- Step 9: ResourceInspect extensions
- Step 10: console-extensions.json
- Step 11: package.json
- Step 12: Locales
- Step 13: RBAC

### Modified: Step 7 — CSS with Design System Integration

**File:** `src/components/<operator-short-name>.css`

This file now applies the custom design system while maintaining plugin-prefixed classes.

#### 7.1: Import Design Theme

Add at the top of the CSS file:

```css
/**
 * [Operator Name] Dashboard Styles
 * Applies custom design system from <operator-short-name>-theme.css
 */

/* Import design system theme variables */
@import '../design-system/<operator-short-name>-theme.css';
```

#### 7.2: Page Layout (with Design System)

```css
/* ========================================
   PAGE LAYOUT
   ======================================== */

.console-plugin-template__inspect-page {
  padding: var(--console-plugin-template--spacing-xl) var(--console-plugin-template--spacing-2xl);
  background-color: var(--console-plugin-template--bg-primary);
  font-family: var(--console-plugin-template--font-body);
  color: var(--console-plugin-template--text-primary);
}

.console-plugin-template__page-title {
  font-family: var(--console-plugin-template--font-heading);
  font-size: var(--console-plugin-template--font-size-4xl);
  font-weight: var(--console-plugin-template--font-weight-bold);
  line-height: var(--console-plugin-template--line-height-tight);
  color: var(--console-plugin-template--text-primary);
  margin-bottom: var(--console-plugin-template--spacing-lg);
}

.console-plugin-template__dashboard-cards {
  display: flex;
  flex-direction: column;
  gap: var(--console-plugin-template--spacing-xl);
}

.console-plugin-template__resource-card {
  background-color: var(--console-plugin-template--bg-secondary);
  border: 1px solid var(--console-plugin-template--border-default);
  border-radius: var(--console-plugin-template--border-radius-lg);
  box-shadow: var(--console-plugin-template--shadow-sm);
  padding: var(--console-plugin-template--spacing-lg);
  transition: box-shadow var(--console-plugin-template--transition-base);
  margin-bottom: 0;
}

.console-plugin-template__resource-card:hover {
  box-shadow: var(--console-plugin-template--shadow-md);
}

.console-plugin-template__card-title {
  font-family: var(--console-plugin-template--font-heading);
  font-size: var(--console-plugin-template--font-size-xl);
  font-weight: var(--console-plugin-template--font-weight-semibold);
  color: var(--console-plugin-template--text-primary);
  margin-bottom: var(--console-plugin-template--spacing-md);
}
```

#### 7.3: Table Structure (with Design System)

```css
/* ========================================
   TABLE STRUCTURE
   ======================================== */

.console-plugin-template__resource-table {
  overflow: hidden;
  border-radius: var(--console-plugin-template--border-radius-md);
}

.console-plugin-template__table-responsive {
  overflow-x: auto;
}

.console-plugin-template__table {
  border-collapse: collapse;
  width: 100%;
  background-color: var(--console-plugin-template--bg-primary);
  font-family: var(--console-plugin-template--font-body);
  font-size: var(--console-plugin-template--font-size-sm);
}

.console-plugin-template__table-th {
  padding: var(--console-plugin-template--spacing-md);
  text-align: left;
  vertical-align: middle;
  background-color: var(--console-plugin-template--bg-secondary);
  border-bottom: 2px solid var(--console-plugin-template--border-default);
  font-weight: var(--console-plugin-template--font-weight-semibold);
  font-size: var(--console-plugin-template--font-size-sm);
  color: var(--console-plugin-template--text-secondary);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.console-plugin-template__table-tr {
  border-bottom: 1px solid var(--console-plugin-template--border-default);
  transition: background-color var(--console-plugin-template--transition-fast);
}

.console-plugin-template__table-tr:hover {
  background-color: var(--console-plugin-template--color-gray-50);
}

.console-plugin-template__table-td {
  padding: var(--console-plugin-template--spacing-md);
  text-align: left;
  vertical-align: middle;
  word-wrap: break-word;
  overflow: hidden;
  color: var(--console-plugin-template--text-primary);
  font-size: var(--console-plugin-template--font-size-sm);
}

.console-plugin-template__table-message {
  padding: var(--console-plugin-template--spacing-lg);
  text-align: center;
  color: var(--console-plugin-template--text-secondary);
}
```

#### 7.4: Action Buttons (with Design System)

```css
/* ========================================
   ACTION BUTTONS
   ======================================== */

.console-plugin-template__action-buttons {
  display: flex;
  gap: var(--console-plugin-template--spacing-sm);
  flex-wrap: nowrap;
}

/* Override PatternFly button styles with design system */
.console-plugin-template__action-inspect {
  flex-shrink: 0;
  background-color: var(--console-plugin-template--color-primary) !important;
  border-color: var(--console-plugin-template--color-primary) !important;
  font-size: var(--console-plugin-template--font-size-sm);
  font-weight: var(--console-plugin-template--font-weight-medium);
  border-radius: var(--console-plugin-template--border-radius-sm);
  transition: all var(--console-plugin-template--transition-fast);
}

.console-plugin-template__action-inspect:hover {
  background-color: color-mix(in srgb, var(--console-plugin-template--color-primary) 85%, black) !important;
  box-shadow: var(--console-plugin-template--shadow-sm);
}

.console-plugin-template__action-delete {
  flex-shrink: 0;
  background-color: var(--console-plugin-template--color-danger) !important;
  border-color: var(--console-plugin-template--color-danger) !important;
  font-size: var(--console-plugin-template--font-size-sm);
  font-weight: var(--console-plugin-template--font-weight-medium);
  border-radius: var(--console-plugin-template--border-radius-sm);
  transition: all var(--console-plugin-template--transition-fast);
}

.console-plugin-template__action-delete:hover {
  background-color: color-mix(in srgb, var(--console-plugin-template--color-danger) 85%, black) !important;
  box-shadow: var(--console-plugin-template--shadow-sm);
}
```

#### 7.5: Loading States (with Design System)

```css
/* ========================================
   LOADING STATES
   ======================================== */

.console-plugin-template__loader {
  display: flex;
  gap: var(--console-plugin-template--spacing-sm);
  align-items: center;
  justify-content: center;
  padding: var(--console-plugin-template--spacing-xl);
}

.console-plugin-template__loader-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background-color: var(--console-plugin-template--color-primary);
  animation: console-plugin-template-loader-bounce 1.2s infinite ease-in-out;
}

.console-plugin-template__loader-dot:nth-child(1) {
  animation-delay: 0s;
}

.console-plugin-template__loader-dot:nth-child(2) {
  animation-delay: 0.2s;
}

.console-plugin-template__loader-dot:nth-child(3) {
  animation-delay: 0.4s;
}

@keyframes console-plugin-template-loader-bounce {
  0%, 80%, 100% {
    transform: scale(0.6);
    opacity: 0.5;
  }
  40% {
    transform: scale(1);
    opacity: 1;
  }
}
```

#### 7.6: Status Labels (with Design System)

```css
/* ========================================
   STATUS LABELS
   ======================================== */

.console-plugin-template__status-label {
  display: inline-flex;
  align-items: center;
  padding: var(--console-plugin-template--spacing-xs) var(--console-plugin-template--spacing-sm);
  border-radius: var(--console-plugin-template--border-radius-sm);
  font-size: var(--console-plugin-template--font-size-xs);
  font-weight: var(--console-plugin-template--font-weight-medium);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.console-plugin-template__status-label--success {
  background-color: color-mix(in srgb, var(--console-plugin-template--color-success) 15%, white);
  color: var(--console-plugin-template--color-success);
  border: 1px solid var(--console-plugin-template--color-success);
}

.console-plugin-template__status-label--danger {
  background-color: color-mix(in srgb, var(--console-plugin-template--color-danger) 15%, white);
  color: var(--console-plugin-template--color-danger);
  border: 1px solid var(--console-plugin-template--color-danger);
}

.console-plugin-template__status-label--warning {
  background-color: color-mix(in srgb, var(--console-plugin-template--color-warning) 15%, white);
  color: var(--console-plugin-template--color-warning);
  border: 1px solid var(--console-plugin-template--color-warning);
}

.console-plugin-template__status-label--info {
  background-color: color-mix(in srgb, var(--console-plugin-template--color-info) 15%, white);
  color: var(--console-plugin-template--color-info);
  border: 1px solid var(--console-plugin-template--color-info);
}
```

#### 7.7: Expandable Rows (if relationships defined)

```css
/* ========================================
   EXPANDABLE ROWS
   ======================================== */

.console-plugin-template__expand-toggle {
  width: 32px;
  padding: 0;
  background: transparent;
  border: none;
  color: var(--console-plugin-template--color-primary);
  cursor: pointer;
  transition: transform var(--console-plugin-template--transition-fast);
}

.console-plugin-template__expand-toggle:hover {
  color: color-mix(in srgb, var(--console-plugin-template--color-primary) 80%, black);
}

.console-plugin-template__expanded-row {
  background-color: var(--console-plugin-template--color-gray-50);
}

.console-plugin-template__expanded-content {
  padding: var(--console-plugin-template--spacing-lg) var(--console-plugin-template--spacing-2xl);
  border-top: 1px solid var(--console-plugin-template--border-default);
  border-bottom: 1px solid var(--console-plugin-template--border-default);
}

.console-plugin-template__child-table {
  background-color: var(--console-plugin-template--bg-primary);
  border: 1px solid var(--console-plugin-template--border-default);
  border-radius: var(--console-plugin-template--border-radius-md);
  box-shadow: var(--console-plugin-template--shadow-sm);
}

.console-plugin-template__no-children {
  font-style: italic;
  color: var(--console-plugin-template--text-secondary);
  padding: var(--console-plugin-template--spacing-md);
  text-align: center;
  font-size: var(--console-plugin-template--font-size-sm);
}
```

#### 7.8: Responsive Design (if design specifies breakpoints)

```css
/* ========================================
   RESPONSIVE BREAKPOINTS
   ======================================== */

/* Tablet and below */
@media (max-width: 768px) {
  .console-plugin-template__inspect-page {
    padding: var(--console-plugin-template--spacing-md);
  }
  
  .console-plugin-template__page-title {
    font-size: var(--console-plugin-template--font-size-3xl);
  }
  
  .console-plugin-template__dashboard-cards {
    gap: var(--console-plugin-template--spacing-md);
  }
  
  .console-plugin-template__table-th,
  .console-plugin-template__table-td {
    padding: var(--console-plugin-template--spacing-sm);
    font-size: var(--console-plugin-template--font-size-xs);
  }
  
  .console-plugin-template__action-buttons {
    flex-direction: column;
    width: 100%;
  }
  
  .console-plugin-template__action-inspect,
  .console-plugin-template__action-delete {
    width: 100%;
  }
}

/* Mobile */
@media (max-width: 480px) {
  .console-plugin-template__page-title {
    font-size: var(--console-plugin-template--font-size-2xl);
  }
  
  /* Hide less critical columns on mobile */
  .console-plugin-template__table-th:nth-child(n+4),
  .console-plugin-template__table-td:nth-child(n+4) {
    display: none;
  }
}
```

### Step 14 (NEW): Font Loading

If custom fonts are specified in the design system:

#### Option A: Google Fonts
Add to `public/index.html`:
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
```

#### Option B: Self-Hosted Fonts
1. Place font files in `public/fonts/`
2. Add `@font-face` rules in theme CSS:
```css
@font-face {
  font-family: 'Inter';
  src: url('/fonts/Inter-Regular.woff2') format('woff2');
  font-weight: 400;
  font-style: normal;
  font-display: swap;
}

@font-face {
  font-family: 'Inter';
  src: url('/fonts/Inter-Bold.woff2') format('woff2');
  font-weight: 700;
  font-style: normal;
  font-display: swap;
}
```

### Phase 2 Validation

**Phase 2 Gate Checklist:**
- [ ] All standard operator-onboarding.md steps completed (Steps 0-13)
- [ ] Design system theme CSS imported and applied
- [ ] Custom colors used via CSS variables (not raw hex)
- [ ] Custom typography applied (fonts loaded, variables used)
- [ ] Custom spacing used in layouts
- [ ] Component styles match design specifications
- [ ] No PatternFly constraint violations
- [ ] `yarn build-dev` succeeds
- [ ] `yarn lint` succeeds (no new errors)
- [ ] Visual review: dashboard matches design intent

---

## Phase 3: Unit Tests with Design System Coverage

**Objective:** Add tests for both K8s functionality and design system application.

### Follow Phase 2 from operator-onboarding.md

All standard testing requirements apply. Additionally:

### Test Design System Integration

Create: `src/design-system/__tests__/design-theme.test.ts`

```typescript
/**
 * Design System Integration Tests
 * Validates that design tokens are correctly applied
 */

describe('Design System Theme', () => {
  beforeAll(() => {
    // Load theme CSS
    require('../<operator-short-name>-theme.css');
  });

  it('should define all required color variables', () => {
    const root = document.documentElement;
    const computedStyle = getComputedStyle(root);
    
    expect(computedStyle.getPropertyValue('--console-plugin-template--color-primary')).toBeTruthy();
    expect(computedStyle.getPropertyValue('--console-plugin-template--color-success')).toBeTruthy();
    expect(computedStyle.getPropertyValue('--console-plugin-template--color-danger')).toBeTruthy();
  });

  it('should define typography variables', () => {
    const root = document.documentElement;
    const computedStyle = getComputedStyle(root);
    
    expect(computedStyle.getPropertyValue('--console-plugin-template--font-heading')).toBeTruthy();
    expect(computedStyle.getPropertyValue('--console-plugin-template--font-size-xl')).toBeTruthy();
  });

  it('should define spacing variables', () => {
    const root = document.documentElement;
    const computedStyle = getComputedStyle(root);
    
    expect(computedStyle.getPropertyValue('--console-plugin-template--spacing-md')).toBeTruthy();
    expect(computedStyle.getPropertyValue('--console-plugin-template--spacing-lg')).toBeTruthy();
  });
});
```

### Test Styled Components

Verify components render with design system classes:

```typescript
import { render } from '@testing-library/react';
import { MyOperatorPage } from '../MyOperatorPage';

describe('MyOperatorPage - Design System', () => {
  it('should apply design system page layout class', () => {
    const { container } = render(<MyOperatorPage />);
    const pageWrapper = container.querySelector('.console-plugin-template__inspect-page');
    expect(pageWrapper).toBeInTheDocument();
  });

  it('should render page title with design system class', () => {
    const { container } = render(<MyOperatorPage />);
    const title = container.querySelector('.console-plugin-template__page-title');
    expect(title).toBeInTheDocument();
  });

  it('should render cards with design system styling', () => {
    const { container } = render(<MyOperatorPage />);
    const card = container.querySelector('.console-plugin-template__resource-card');
    expect(card).toBeInTheDocument();
  });
});
```

### Phase 3 Validation

**Phase 3 Gate Checklist:**
- [ ] All standard unit tests from operator-onboarding.md Phase 2 completed
- [ ] Design system integration tests added
- [ ] Component tests verify design system classes applied
- [ ] `yarn test` succeeds (all suites pass)
- [ ] `yarn lint` succeeds (no new errors)
- [ ] Test coverage meets requirements (>70% for new code)

---

## Definition of Done (Three Phases)

### Phase 1: Design System Analysis ✅
- [ ] Design code analyzed and tokens extracted
- [ ] `design-mapping.md` created with complete token mapping
- [ ] `<operator-short-name>-theme.css` created with CSS variables
- [ ] PatternFly variable overrides documented
- [ ] Font loading strategy determined
- [ ] Dark mode variants addressed
- [ ] No design values inferred (all from actual design code)

### Phase 2: Dashboard Implementation ✅
- [ ] All operator-onboarding.md functional requirements met
- [ ] Design theme CSS imported in operator CSS file
- [ ] Custom colors applied via CSS variables
- [ ] Custom typography applied (fonts loaded, variables used)
- [ ] Custom spacing applied in layouts
- [ ] Component styles match design specifications
- [ ] Tables styled per design (headers, rows, hover states)
- [ ] Buttons styled per design (colors, borders, shadows)
- [ ] Cards styled per design (backgrounds, borders, padding)
- [ ] Responsive behavior implemented (if design specifies)
- [ ] `yarn build-dev` succeeds
- [ ] `yarn lint` succeeds
- [ ] Visual review confirms design match

### Phase 3: Testing ✅
- [ ] Standard operator tests completed
- [ ] Design system integration tests added
- [ ] Component rendering tests verify design classes
- [ ] `yarn test` succeeds
- [ ] `yarn lint` succeeds
- [ ] Coverage meets requirements

### Cross-Phase Validation ✅
- [ ] No PatternFly constraints violated
- [ ] No hex colors in component code (only in theme CSS variables)
- [ ] Plugin-prefixed classes used throughout
- [ ] Dark mode compatibility maintained
- [ ] Accessibility preserved (WCAG 2.1 AA minimum)
- [ ] No breaking changes to K8s functionality

---

## Final Response Format

When all three phases complete, provide:

### 1. Phase 1 Summary — Design System Mapping
```
Design Source: [Figma / Google Stitch / Tailwind / etc.]

Extracted Tokens:
- Colors: [N colors mapped]
- Typography: [N font families, N sizes, N weights]
- Spacing: [N spacing tokens]
- Components: [button, card, table, etc.]

Files Created:
- src/design-system/design-mapping.md
- src/design-system/<operator-short-name>-theme.css

Key Design Decisions:
- Font loading: [strategy]
- Dark mode: [supported / not provided by design]
- PatternFly overrides: [which variables overridden]
```

### 2. Phase 2 Summary — Dashboard Implementation
```
Operator: [Name]
Resources: [list of exposed CRDs]

Files Created/Modified:
- src/hooks/useOperatorDetection.ts (extended)
- src/components/crds/index.ts (extended)
- src/components/<KindPlural>Table.tsx (created)
- src/<OperatorShortName>Page.tsx (created)
- src/components/<operator-short-name>.css (created with design system)
- src/ResourceInspect.tsx (extended)
- console-extensions.json (extended)
- package.json (extended)
- locales/en/plugin__console-plugin-template.json (extended)
- charts/.../rbac-clusterroles.yaml (extended)

Design System Applied:
- Primary color: [value] → [CSS variable]
- Typography: [font family]
- Spacing: [base unit]
- Component overrides: [button, card, table]

Validation:
✅ yarn build-dev
✅ yarn lint
✅ Visual design match confirmed
```

### 3. Phase 3 Summary — Testing
```
Test Files Created/Modified:
- src/design-system/__tests__/design-theme.test.ts (created)
- src/__tests__/<OperatorShortName>Page.test.tsx (created)
- src/components/__tests__/<KindPlural>Table.test.tsx (created)
- [other test files...]

Test Coverage:
- Operator detection: [states covered]
- Tables: [happy path, empty, error]
- Design system: [CSS variables, classes]
- Components: [rendering, styling]

Validation:
✅ yarn test (all suites pass)
✅ yarn lint (no errors)
✅ Coverage: [X%]
```

### 4. Design System Documentation
```
Design Token Count:
- Colors: [N]
- Typography: [N]
- Spacing: [N]
- Component overrides: [N]

PatternFly Compatibility:
- Variables overridden: [list]
- Constraints maintained: ✅
- Dark mode: [status]

Known Deviations from Design:
- [None / List any compromises made for PatternFly compatibility]

Recommendations:
- [Any suggestions for design system improvements]
```

### 5. Deployment Readiness
```
Build Output: ✅
Linting: ✅
Tests: ✅
RBAC: ✅
i18n: ✅

Next Steps:
1. Build container image
2. Push to registry
3. Deploy via Helm chart
4. Enable plugin in OpenShift Console
```

---

## Design System Best Practices

### Color Mapping Strategy

**DO:**
- ✅ Map semantic colors (primary, success, danger) to PatternFly palette variables
- ✅ Use `color-mix()` for hover/active states (CSS Color Level 5)
- ✅ Define both light and dark mode variants
- ✅ Maintain WCAG AA contrast ratios (4.5:1 for text, 3:1 for UI)

**DON'T:**
- ❌ Use hex colors directly in component styles
- ❌ Override too many PatternFly variables (breaks console theming)
- ❌ Ignore dark mode (users expect it in OpenShift Console)

### Typography Strategy

**DO:**
- ✅ Load custom fonts with `font-display: swap` (FOIT prevention)
- ✅ Provide system font fallbacks
- ✅ Use relative units (rem/em) for font sizes where possible
- ✅ Match PatternFly's typographic scale when close

**DON'T:**
- ❌ Load excessive font weights/variants (performance)
- ❌ Use custom fonts for monospace code (use PatternFly's)
- ❌ Override PatternFly body font size globally (breaks console)

### Spacing Strategy

**DO:**
- ✅ Map design spacing to closest PatternFly spacer tokens
- ✅ Use consistent spacing scale (4px/8px base units)
- ✅ Apply spacing via design system variables, not magic numbers

**DON'T:**
- ❌ Override PatternFly spacing globally (affects all components)
- ❌ Use pixel values directly in components
- ❌ Mix spacing scales (stay consistent with design)

### Component Override Strategy

**DO:**
- ✅ Scope overrides to plugin-prefixed classes
- ✅ Use `!important` sparingly (only to override PatternFly when needed)
- ✅ Test overrides with PatternFly component variants (primary, secondary, etc.)
- ✅ Document why each override is necessary

**DON'T:**
- ❌ Override PatternFly component internals (.pf-c-button__icon, etc.)
- ❌ Break PatternFly component accessibility (ARIA, focus states)
- ❌ Remove PatternFly component functionality

---

## Troubleshooting

### Issue: Design colors don't appear in components

**Cause:** CSS variables not imported or scoped incorrectly

**Solution:**
1. Verify `@import '../design-system/<operator-short-name>-theme.css';` in operator CSS
2. Check CSS variable names match (typo check)
3. Verify variables defined at `:root` level (global scope)
4. Use browser DevTools to inspect computed CSS variable values

### Issue: Custom fonts not loading

**Cause:** Font files not found or CORS issues

**Solution:**
1. Check font file paths (relative to public/ directory)
2. Verify font files exist and are accessible
3. Check browser Network tab for 404s or CORS errors
4. For Google Fonts, verify `<link>` tag in index.html
5. Check `font-display: swap` for fallback rendering

### Issue: Dark mode looks broken

**Cause:** Only light mode colors defined

**Solution:**
1. Add `@media (prefers-color-scheme: dark)` overrides in theme CSS
2. Test with browser DevTools dark mode emulation
3. Verify text contrast in dark mode meets WCAG AA
4. Provide dark variants for all semantic colors

### Issue: PatternFly components look wrong

**Cause:** Overly aggressive variable overrides

**Solution:**
1. Reduce scope of PatternFly variable overrides
2. Override only specific palette colors, not base tokens
3. Test with multiple PatternFly component types
4. Use scoped CSS classes instead of global overrides

### Issue: Design doesn't match Figma exactly

**Cause:** PatternFly constraints or browser limitations

**Solution:**
1. Document deviations in design-mapping.md
2. Prioritize functional requirements over pixel perfection
3. Use closest PatternFly patterns when possible
4. Escalate to design team if critical brand elements compromised

### Issue: Build fails with "Invalid module export 'default'"

**Cause:** Component referenced in console-extensions.json uses wrong export

**Solution:**
1. Verify `$codeRef` uses `ModuleName.ExportName` format
2. Check component uses `export const` (named export), not `export default`
3. Match `exposedModules` in package.json

---

## Advanced: Multi-Brand Design Systems

If your design system supports multiple brands/themes:

### Structure

```
src/design-system/
  ├── base-theme.css          # Shared base variables
  ├── brand-a-theme.css       # Brand A overrides
  ├── brand-b-theme.css       # Brand B overrides
  └── theme-loader.ts         # Runtime theme selector
```

### Implementation

**base-theme.css:**
```css
:root {
  /* Shared structural tokens */
  --console-plugin-template--spacing-unit: 8px;
  --console-plugin-template--border-radius: 6px;
}
```

**brand-a-theme.css:**
```css
@import './base-theme.css';

:root {
  /* Brand A colors */
  --console-plugin-template--color-primary: #1E40AF;
  --console-plugin-template--font-heading: 'Inter', sans-serif;
}
```

**brand-b-theme.css:**
```css
@import './base-theme.css';

:root {
  /* Brand B colors */
  --console-plugin-template--color-primary: #7C3AED;
  --console-plugin-template--font-heading: 'Roboto', sans-serif;
}
```

**theme-loader.ts:**
```typescript
export const loadTheme = (brand: 'a' | 'b') => {
  const themeFile = brand === 'a' ? 'brand-a-theme.css' : 'brand-b-theme.css';
  import(`./design-system/${themeFile}`);
};
```

---

## Appendix A: Design Token Extraction Examples

### From Figma Design Tokens JSON

Input:
```json
{
  "global": {
    "colors": {
      "primary": { "value": "#1E40AF" },
      "secondary": { "value": "#64748B" }
    },
    "fontFamilies": {
      "heading": { "value": "Inter" }
    },
    "spacing": {
      "4": { "value": "16px" }
    }
  }
}
```

Extraction:
```css
:root {
  --console-plugin-template--color-primary: #1E40AF;
  --console-plugin-template--color-secondary: #64748B;
  --console-plugin-template--font-heading: 'Inter', sans-serif;
  --console-plugin-template--spacing-md: 16px;
}
```

### From Tailwind Config

Input:
```js
module.exports = {
  theme: {
    extend: {
      colors: {
        brand: {
          primary: '#1E40AF',
          secondary: '#64748B'
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui']
      },
      spacing: {
        '4.5': '18px'
      }
    }
  }
}
```

Extraction:
```css
:root {
  --console-plugin-template--color-primary: #1E40AF;
  --console-plugin-template--color-secondary: #64748B;
  --console-plugin-template--font-body: 'Inter', system-ui, sans-serif;
  --console-plugin-template--spacing-custom: 18px;
}
```

### From Google Material Theme

Input:
```json
{
  "color": {
    "primary": "#6200EE",
    "secondary": "#03DAC6"
  },
  "typography": {
    "headline1": {
      "fontFamily": "Roboto",
      "fontSize": 96,
      "fontWeight": 300
    }
  },
  "spacing": 8
}
```

Extraction:
```css
:root {
  --console-plugin-template--color-primary: #6200EE;
  --console-plugin-template--color-secondary: #03DAC6;
  --console-plugin-template--font-heading: 'Roboto', sans-serif;
  --console-plugin-template--font-size-h1: 96px;
  --console-plugin-template--font-weight-light: 300;
  --console-plugin-template--spacing-unit: 8px;
}
```

---

## Appendix B: PatternFly Variable Reference

Common PatternFly variables to override for design system integration:

### Colors
```css
--pf-v6-global--palette--blue-700          /* Primary brand color */
--pf-v6-global--palette--green-500         /* Success color */
--pf-v6-global--palette--red-500           /* Danger color */
--pf-v6-global--palette--orange-500        /* Warning color */
--pf-t--global--background--color--primary--default
--pf-t--global--text--color--default
--pf-t--global--border--color--default
```

### Typography
```css
--pf-v6-global--FontFamily--heading
--pf-v6-global--FontFamily--text
--pf-v6-global--FontSize--4xl              /* Page titles */
--pf-v6-global--FontSize--xl               /* Section headers */
--pf-v6-global--FontSize--md               /* Body text */
--pf-v6-global--FontWeight--bold
```

### Spacing
```css
--pf-t--global--spacer--xs                 /* 4px */
--pf-t--global--spacer--sm                 /* 8px */
--pf-t--global--spacer--md                 /* 16px */
--pf-t--global--spacer--lg                 /* 24px */
--pf-t--global--spacer--xl                 /* 32px */
```

### Components
```css
--pf-v6-global--BorderRadius--sm
--pf-v6-global--BoxShadow--sm
--pf-v6-c-button--PaddingTop
--pf-v6-c-card--BackgroundColor
```

**Full reference:** https://www.patternfly.org/design-foundations/css-variables

---

## Summary

This enhanced prompt combines:
1. ✅ **K8s operator logic** from operator-onboarding.md (unchanged)
2. ✅ **Design system integration** from Figma/Stitch/custom code
3. ✅ **PatternFly compatibility** via CSS variable mapping
4. ✅ **Three-phase workflow** (design → implementation → tests)
5. ✅ **Comprehensive validation** at each phase

**Result:** Production-ready operator dashboards with custom branding while maintaining OpenShift Console plugin standards.
