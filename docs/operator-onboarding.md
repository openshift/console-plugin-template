
# Add a New Operator to the OpenShift Console Plugin

Copy the template, fill in operator details, run it. Works on a clean repo (after `git stash`) or with existing operators already added.

---

## End Goal

- **Operator dashboard** at `/<operator-short-name>`: page title plus one **Card + table per resource kind**. Tables use the shared **ResourceTable** component (see [Existing shared components](#existing-shared-components)).
- **Sidebar:** The dashboard link appears under **Plugins** in the admin perspective. If the Plugins section does not exist, create it first; then add the operator link. Do not duplicate the section or the link if they already exist.
- **Per-row actions:** Each custom resource row has an **Inspect** button (navigates to the resource detail page) and a **Delete** button (opens confirmation modal). Both must be **buttons** (not link-styled only): Inspect with a sky-blue background, Delete with a red background.
- **Resource detail dashboard (inspect page):** Clicking Inspect opens `/<operator-short-name>/inspect/<plural>/[namespace/]<name>`. The **ResourceInspect** component (see [Existing shared components](#existing-shared-components)) shows Metadata, Labels, Annotations, Specification, Status, and Events in a **Card + Grid** layout with a back button—no tabs. When adding a new operator, **extend** ResourceInspect’s maps and models; do not replace its layout or structure.
- **Optional:** Overview dashboard (summary count cards above tables) per Step 7b. Not required.
- **Expandable rows (one-to-many relationships):** Parent resources can have expandable rows showing related child resources inline. When a relationship is defined, the parent table row has an expand/collapse toggle; expanding reveals a nested table of child resources filtered by that parent. See **Step 6b** for implementation details.

---

## Visual & Styling Standards

All operator dashboards must follow these styling patterns for a professional, consistent appearance:

**Page Layout:**
- ✅ Wrap all content in `console-plugin-template__inspect-page` div (provides proper padding)
- ✅ Display prominent `<Title headingLevel="h1" size="xl">` at top of page
- ✅ Use `console-plugin-template__dashboard-cards` wrapper for Cards (vertical flex with gap)

**Navigation:**
- ✅ Use React Router `<Link to>` for all navigation (SPA, no page reloads)
- ❌ Never use `<a href>` or `window.location.href`

**Action Buttons:**
- ✅ Put className on the `<Button>` component, not the wrapping `<Link>`
- ✅ Use PatternFly `variant` prop for colors (`variant="primary"` = blue, `variant="danger"` = red)
- ❌ Never add custom background-color/border-color CSS for buttons
- ❌ Never put button styling classes on the Link wrapper

**Tables:**
- ✅ Use plugin-prefixed CSS classes: `console-plugin-template__table`, `__table-th`, `__table-td`, `__table-tr`
- ✅ Define styles via CSS classes with PatternFly variables
- ❌ Never use OpenShift console classes (`co-m-*`, `table`, `table-hover`)
- ❌ Never use inline `style` attributes for table padding/layout

**Loading States:**
- ✅ Page-level: `<Spinner size="lg">` wrapped in `inspect-page` div
- ✅ Table-level: Three-dot animated loader (`console-plugin-template__loader-dot`)

**Empty States:**
- ✅ Use PatternFly 6 API: `<EmptyState titleText="..." icon={SearchIcon} headingLevel="h4">`
- ❌ Never use separate `<Title>` or `EmptyStateHeader` components

**CSS:**
- ✅ Only PatternFly CSS variables (e.g., `var(--pf-t--global--spacer--lg)`)
- ✅ Prefix all custom classes with `console-plugin-template__`
- ❌ Never use hex colors
- ❌ Never use `.pf-` or `.co-` prefixes for custom classes

**Result:** Professional dashboards with proper spacing, smooth navigation, and visual consistency.

---

## Existing Shared Components

The project already includes:

- **`src/components/ResourceTable.tsx`** — Shared table: accepts `columns` (title, optional width), `rows` (cells as React nodes), `loading`, `error`, `emptyStateTitle`, `emptyStateBody`, `selectedProject`, `data-test`. Renders a plain `<table>` with thead/tbody using **plugin-prefixed CSS classes** (`console-plugin-template__table`, `__table-th`, `__table-td`, etc.), loading (three-dot animated loader), error Alert, empty EmptyState, or data rows. Use this for **all** operator resource tables; do not use VirtualizedTable. Expects corresponding CSS classes defined in operator CSS file (see Step 7).
- **`ResourceTableRowActions`** (exported from the same file) — Renders Inspect + Delete **buttons** for one row. Structure:
  ```tsx
  <div className=”console-plugin-template__action-buttons”>
    <Link to={inspectHref}>
      <Button className=”console-plugin-template__action-inspect” variant=”primary” size=”sm”>
        {t('Inspect')}
      </Button>
    </Link>
    <Button className=”console-plugin-template__action-delete” variant=”danger” size=”sm” onClick={launchDeleteModal}>
      {t('Delete')}
    </Button>
  </div>
  ```
  **Critical:** `className` goes on `<Button>`, NOT on `<Link>`. Colors come from `variant` prop (`primary`=blue, `danger`=red). Use it in the Actions cell of each row so `useDeleteModal` is called per row (hooks cannot be called inside `.map()`).
- **`src/ResourceInspect.tsx`** — Shared resource detail page: Card + Grid layout, back button, Metadata/Labels/Annotations/Spec/Status/Events cards, optional “Show/Hide sensitive data” for spec/status. When adding a new operator, **add** entries to `DISPLAY_NAMES`, `getResourceModel(resourceType)`, and `getPagePath(resourceType)`; do not rewrite the component or change its layout/styling pattern.

---

## Prompt Template (copy, fill, run)

```text
Add a new operator to this OpenShift console plugin: [OPERATOR_NAME].

Input:
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
4) Optional column overrides: [none] or per-resource list of columns (title, id, jsonPath, type?) to use instead of the operator-agnostic algorithm.
5) Optional relationships (one-to-many): [none] or define parent-child relationships for expandable rows:
   - parent: [ParentKind]
     child: [ChildKind]
     matchField: [field in child referencing parent, e.g. "spec.pipelineRef.name"]
     matchType: [field | ownerRef | label]
   (repeat block for each relationship, or omit entirely if no relationships)
6) API group verification (paste the output of the command below — REQUIRED):
   Run on the cluster before filling in groups/versions above:
   ```bash
   oc api-resources | grep -i <operator-keyword>
   # e.g. for NFD: oc api-resources | grep -i feature
   # e.g. for cert-manager: oc api-resources | grep -i cert
   ```
   Paste full output here: [PASTE OUTPUT]
   Use the APIVERSION column values as the authoritative source for groups and versions.
   Do NOT rely on upstream documentation for API groups — OpenShift-packaged operators
   frequently use different groups (e.g. *.openshift.io, *.k8s-sigs.io) from the
   community upstream (e.g. *.kubernetes.io).

Follow the implementation specification in this document exactly.
Start implementation immediately. Do not ask for confirmation.
If any input is missing EXCEPT for field 6, infer from upstream CRD docs and record inferences in the final summary.
Field 6 (API group verification) must NOT be inferred — it must be obtained from the actual cluster.
```

---

## What NOT to Do

- **Do NOT misuse `useK8sModel` return value.** The hook returns `[model, inFlight]` where `inFlight` is `true` **while loading** and `false` when complete. A common mistake is naming the second parameter `loaded` and checking `if (!loaded) return 'loading'` — this is **backwards** because `!inFlight` is `false` during loading, causing the check to be skipped. The page will either be stuck loading forever or immediately show "not installed". **Correct pattern:** `if (inFlight) return 'loading'`. See Step 2 for the correct implementation.
- **Do NOT assume API groups from upstream documentation.** OpenShift-packaged operators routinely use different groups than the community upstream (e.g. `nfd.openshift.io` instead of `nfd.kubernetes.io`, `*.k8s-sigs.io` instead of `*.kubernetes.io`). Always run `oc api-resources | grep -i <keyword>` on the actual cluster and use the `APIVERSION` column as the authoritative source. Wrong groups cause `useK8sModel` to return `null`, which shows "Operator not installed" even when the operator is running.
- **Do NOT assume cluster-scoped vs namespaced** from upstream docs. Check the `NAMESPACED` column in `oc api-resources` output — the same CRD kind can be namespaced in one distribution and cluster-scoped in another. Namespaced resources require a `selectedProject` prop and a Namespace column in the table; cluster-scoped resources do not.
- **Do NOT use `consoleFetchJSON`** for operator/CRD detection; use `useK8sModel` only.
- **Do NOT use VirtualizedTable** for the operator dashboard resource tables; use **ResourceTable** with `columns` and `rows`.
- **Do NOT call `useDeleteModal` inside a `.map()` callback.** Use a per-row component (e.g. `ResourceTableRowActions`) that receives the resource and calls `useDeleteModal(resource)`.
- **Do NOT use link-styled-only actions:** Inspect and Delete must be real **buttons** with proper colors. Use PatternFly's `variant` prop: `variant="primary"` (blue) for Inspect, `variant="danger"` (red) for Delete. Never add custom background-color/border-color CSS for buttons.
- **Do NOT put button styling `className` on the `<Link>` wrapper.** Put `className` (e.g., `console-plugin-template__action-inspect`) on the `<Button>` component itself. Putting className on Link can break PatternFly button styling.
- **Do NOT use hex colors** (e.g. `#1e1e1e`, `#374151`) in CSS or inline styles. Use **PatternFly CSS variables only** (e.g. `var(--pf-v6-global--BackgroundColor--200)`, `var(--pf-v6-global--BorderColor--100)`).
- **Do NOT use `.pf-` or `.co-` prefixed class names** for your own structure (e.g. `co-m-loader`, `co-m-pane__body`). Use **`console-plugin-template__`** prefix for all custom classes.
- **Do NOT use OpenShift console CSS classes** like `co-m-loader`, `co-m-table-grid`, `table`, `table-hover`. Replace with plugin-prefixed classes: `console-plugin-template__loader`, `console-plugin-template__table`, etc.
- **Do NOT use `window.location.href` or `<a href>` for navigation.** Use React Router’s `<Link to>` for SPA navigation without page reloads.
- **Do NOT use inline styles** for table padding, layout, or spacing. Use CSS classes with PatternFly variables instead.
- **Do NOT use PatternFly 6 `EmptyStateHeader` or `EmptyStateIcon`**; they do not exist. Use props on `<EmptyState>`: `titleText`, `icon={SearchIcon}`, `headingLevel`.
- **Do NOT use `Label`’s `variant` prop for status colors.** Use the **`status`** prop: `status="success"` (green), `status="danger"` (red), `status="warning"` (orange). (`variant` is for outline/filled/overflow/add.)
- **Do NOT use `PageSection variant="light"`**; use `"default"` or `"secondary"`.
- **Do NOT assume `useActiveNamespace()` returns `’all’`** when all namespaces are selected; it returns **`#ALL_NS#`**.
- **Do NOT create two separate routes for inspect** (e.g. one for namespaced and one for cluster-scoped). Use **one** route with `path: ["/<operator-short-name>/inspect"]` and `exact: false`; the component parses the rest of the path.
- **Do NOT put the operator dashboard link under `section: "home"`.** It must be **`section: "plugins"`** so it appears under Plugins.
- **Do NOT rely on margin alone for spacing between table cards** if it collapses. Use a **wrapper div** with `display: flex`, `flex-direction: column`, and **`gap`** (e.g. `console-plugin-template__dashboard-cards`).
- **Do NOT add `titleFormat` to table column config** when using the SDK’s `TableColumn` type elsewhere; it is not part of that type. For ResourceTable, columns only have `title` and optional `width`.
- **Do NOT rewrite `ResourceInspect.tsx`** when adding an operator. Extend its `DISPLAY_NAMES`, `getResourceModel`, and `getPagePath`; keep the existing Card + Grid layout and back button.
- **Do NOT use `$codeRef` with only the module name** (e.g. `"$codeRef": "CertManagerPage"`) for route components in `console-extensions.json`. The Console ExtensionValidator treats that as the **default** export; if the module uses a **named** export (e.g. `export const CertManagerPage`), the build fails with **"Invalid module export ‘default’ in extension [N] property ‘component’"**. Always use the **`moduleName.exportName`** form (e.g. `"$codeRef": "CertManagerPage.CertManagerPage"`, `"$codeRef": "ResourceInspect.ResourceInspect"`).
- **Do NOT fetch all children upfront for expandable rows.** Children must be fetched lazily only when the parent row is expanded (performance).
- **Do NOT use PatternFly's `<Table>` with `expandable` variant** for parent-child relationships. Use the custom `ExpandableResourceTable` component that renders a nested child table when expanded.
- **Do NOT hardcode parent-child matching logic.** Use the `matchField` and `matchType` from the relationship definition to filter children dynamically.

---

## Critical Rules (read before coding)

**Functional:**
0. **Verify API groups on the cluster FIRST.** Before writing any code, run:
   ```bash
   oc api-resources | grep -i <operator-keyword>
   ```
   Use the `APIVERSION` column for the correct `group/version` and the `NAMESPACED` column for scope. Do not trust upstream docs or OperatorHub listings for these values — OpenShift distributions frequently use different API groups (e.g. `nfd.openshift.io/v1` instead of `nfd.kubernetes.io/v1`). Wrong values will cause `useK8sModel` to return `null`, showing "Operator not installed" even when the operator is installed and running.
1. **Operator detection:** Use **`useK8sModel`** only. `consoleFetchJSON` to CRD/API-group endpoints fails silently due to RBAC in the console proxy. **IMPORTANT:** `useK8sModel` returns `[model, inFlight]` where `inFlight` is `true` **while loading**. Check `if (inFlight) return 'loading'` — NOT `if (!inFlight)`.
2. **EmptyState (PatternFly 6):** Use `<EmptyState titleText="..." icon={SearchIcon} headingLevel="h2"><EmptyStateBody>...</EmptyStateBody></EmptyState>`.
3. **`useActiveNamespace`** returns **`#ALL_NS#`** when all namespaces are selected (not `'all'`).
4. **Inspect route:** Single route with `path: ["/<operator-short-name>/inspect"]`, `exact: false`. Component parses path segments internally.
5. **Navigation:** Operator link under **Plugins** (`section: "plugins"`). Create Plugins section first if missing; do not duplicate section or link.
6. **`useK8sWatchResource`:** Use the **`groupVersionKind`** object (`{ group, version, kind }`), not the deprecated `kind` string.
7. **i18n namespace:** **`plugin__console-plugin-template`**.
8. **Cluster-scoped resources:** No Namespace column, no `selectedProject` on the table, inspect URL has 2 segments (`/<plural>/<name>`), no `/namespaces/<ns>/` in delete path.
9. **`console-extensions.json` component references:** Every route `component` must use **`$codeRef`** in the form **`moduleName.exportName`** (e.g. `CertManagerPage.CertManagerPage`, `ResourceInspect.ResourceInspect`). The plugin SDK resolves a bare module name (e.g. `CertManagerPage`) as the **default** export; our page and inspect components use **named** exports. Using only the module name causes the build to fail with "Invalid module export 'default' in extension [N] property 'component'". Page and ResourceInspect modules must **export const** the component (named export); then reference it as `"<ModuleName>.<ExportName>"` in `console-extensions.json`.

**Styling (for professional appearance):**
10. **Page layout:** All page states must wrap content in `console-plugin-template__inspect-page` div. Add `<Title headingLevel="h1" size="xl">` at top with bottom margin. Nest Cards in `console-plugin-template__dashboard-cards` wrapper.
11. **Navigation:** Use React Router **`<Link to>`** for all links (table names, action buttons). Never use `<a href>` or `window.location.href` (causes full page reload).
12. **Button structure:** Put `className` on the `<Button>` component, NOT on the wrapping `<Link>`. Button colors come from `variant` prop (`variant="primary"` for blue Inspect, `variant="danger"` for red Delete). Never add custom background-color/border-color CSS for buttons.
13. **CSS classes:** Replace ALL OpenShift console classes (`co-m-loader`, `co-m-table-grid`, `table`, `table-hover`) with plugin-prefixed classes (`console-plugin-template__loader`, `console-plugin-template__table`, etc.). See Step 7 for complete list.
14. **CSS variables only:** Use PatternFly CSS variables (e.g., `var(--pf-t--global--spacer--lg)`), never hex colors. Prefix all custom classes with **`console-plugin-template__`**. **Keyframes names** must be kebab-case (e.g. `console-plugin-template-loader-bounce`).
15. **No inline styles:** Table elements (`th`, `td`, `tr`) must use CSS classes, not inline `style` attributes for padding/alignment/borders.

---

## Read-First Files

**Before reading any files, run this on the cluster:**
```bash
oc api-resources | grep -i <operator-keyword>
```
Use the `APIVERSION` and `NAMESPACED` columns as the authoritative source for groups, versions, and resource scope. See Step 0 for details.

| File | Purpose |
|------|--------|
| `src/components/ResourceTable.tsx` | Shared table API (columns, rows, loading, error, empty); `ResourceTableRowActions` for Inspect/Delete buttons (className on Button, variant for colors) |
| `src/ResourceInspect.tsx` | Shared inspect page (Card + Grid, back button); extend DISPLAY_NAMES, getResourceModel, getPagePath |
| `src/hooks/useOperatorDetection.ts` | Operator CRD detection hook |
| `src/components/crds/index.ts` | K8sModel and TS interfaces per kind |
| `src/components/crds/Events.ts` | plural → Kind for events |
| `src/components/OperatorNotInstalled.tsx` | Generic “not installed” empty state |
| `src/components/<operator-short-name>.css` | Shared operator CSS (cards, tables, buttons, inspect) |
| `src/components/ExpandableResourceTable.tsx` | Shared expandable table for parent-child relationships (create if relationships defined) |
| `console-extensions.json` | Routes and nav |
| `package.json` | `consolePlugin.exposedModules` |
| `locales/en/plugin__console-plugin-template.json` | English strings |
| `charts/openshift-console-plugin/templates/rbac-clusterroles.yaml` | RBAC for new API groups |

Create any of the above if missing; when they exist, **extend** them (do not replace shared structure).

---

## Naming Conventions

- **OPERATOR_SHORT_NAME:** recognizable short name, lowercase kebab-case (e.g. "cert-manager Operator for Red Hat OpenShift" → `cert-manager`).

| Concept | Pattern | Example |
|---------|---------|---------|
| Page path | `/<operator-short-name>` | `/cert-manager` |
| Page component | `src/<OperatorShortName>Page.tsx` | `src/CertManagerPage.tsx` |
| Table components | `src/components/<KindPlural>Table.tsx` | `src/components/CertificatesTable.tsx` |
| CSS | `src/components/<operator-short-name>.css` | `src/components/cert-manager.css` |
| Inspect (namespaced) | `/<page>/inspect/<plural>/<namespace>/<name>` | `/cert-manager/inspect/certificates/default/my-cert` |
| Inspect (cluster-scoped) | `/<page>/inspect/<plural>/<name>` | `/cert-manager/inspect/clusterissuers/my-issuer` |

---

## Operator Dashboard Column Selection

Tables MUST follow this column logic (implement when building rows for ResourceTable):

1. **Always:** Name (link to inspect), Namespace (if namespaced).
2. **Optional:** Columns from CRD `additionalPrinterColumns` (priority 0; priority 1 only if total ≤ 8). Use each column’s `jsonPath`; `type: date` → `<Timestamp>`; status/conditions → Label with **`status`** prop (success/danger/warning).
3. **Fallback** if no additionalPrinterColumns: Name, Namespace (if namespaced), Status (from `status.conditions[type=Ready]`), Age (`metadata.creationTimestamp`), Actions.
4. **Always last:** Actions column with **Inspect** button (sky blue) and **Delete** button (red), using **ResourceTableRowActions** so `useDeleteModal` is called per row.
5. User-provided column overrides (if any) override the above; document them in the summary.

---

## Implementation Steps

### Step 0 — Verify API groups on the cluster (REQUIRED before any coding)

Run this command on the cluster and record the output:

```bash
oc api-resources | grep -i <operator-keyword>
# Example: oc api-resources | grep -i cert
# Example: oc api-resources | grep -i feature
# Example: oc api-resources | grep -i pipeline
```

From the output, use:
- **`APIVERSION` column** → determines the correct `group` and `version` for every K8s model and GVK object in the code. Format is `<group>/<version>` (e.g. `nfd.openshift.io/v1` → group `nfd.openshift.io`, version `v1`). An entry with no slash (e.g. `v1`) means core group (`""`).
- **`NAMESPACED` column** → `true` means the resource needs a `selectedProject` prop and a Namespace column; `false` means cluster-scoped (no namespace in inspect URL, no `selectedProject`).
- **`KIND` column** → confirms the exact kind name to use.

**Common pitfall:** OpenShift-packaged operators often register CRDs under their own `*.openshift.io` or `*.k8s-sigs.io` group instead of the upstream `*.kubernetes.io` group. If the wrong group is used, `useK8sModel` returns `null` and the dashboard shows "Operator not installed" even though the operator is running.

Do not proceed to Step 1 until you have the verified API group/version/scope for every resource kind you plan to expose.

---

### Step 1 — Directories

```bash
mkdir -p src/hooks src/components/crds
```

### Step 2 — `src/hooks/useOperatorDetection.ts`

Use `useK8sModel` with `{ group, version, kind }` for the primary resource. Export `OperatorStatus`, `OperatorInfo`, `<OPERATOR>_OPERATOR_INFO`, and `useOperatorDetection()`. If the file exists, add the new operator’s info and extend the hook.

### Step 3 — `src/components/crds/index.ts`

For each resource kind, export a **K8sModel** and a TypeScript interface extending `K8sResourceCommon` with optional `spec`/`status`. Append if the file exists.

### Step 4 — `src/components/crds/Events.ts`

Add `plural: 'Kind'` to **RESOURCE_TYPE_TO_KIND** for each new resource.

### Step 5 — `src/components/OperatorNotInstalled.tsx`

Create only if missing. Generic empty state with `EmptyState` (titleText, icon={SearchIcon}, headingLevel), `EmptyStateBody`, and operator display name message.

### Step 6 — Table components (`src/components/<KindPlural>Table.tsx`)

**Use ResourceTable.** One file per resource kind.

- **Import React Router Link:** Add `import { Link } from ‘react-router-dom’;` at the top.
- Build **columns**: array of `{ title, width? }` (Name, Namespace if namespaced, then algorithm columns, then Actions).
- Build **rows**: from `useK8sWatchResource` list; each row’s **cells** array includes:
  - **Name cell:** Use `<Link key="name" to={inspectHref}>{name}</Link>` for SPA navigation (not `<a href>`).
  - Namespace (if namespaced), Status (Label with **status** prop), Created (Timestamp).
  - **Actions cell:** `<ResourceTableRowActions resource={obj} inspectHref={inspectHref} />` (already uses Link internally).
- Pass **loading** (`!loaded && !loadError`), **error** (`loadError?.message`), **emptyStateTitle**, **emptyStateBody**, **selectedProject** (namespaced only), **data-test**.
- **Namespaced:** `selectedProject`, inspect href `/<page>/inspect/<plural>/${namespace}/${name}`.
- **Cluster-scoped:** no `selectedProject`, inspect href `/<page>/inspect/<plural>/${name}`.

**Example Name cell:**
```tsx
<Link key="name" to={inspectHref}>
  {name}
</Link>
```

**Actions cell:** Always use the shared `ResourceTableRowActions` component. Do NOT implement custom button logic. The component already has the correct structure with `className` on buttons (not on Link) and `variant` prop for colors.

Do **not** use VirtualizedTable, `<a href>`, or call `useDeleteModal` inside `.map()`.

### Step 6b — Expandable Row Components (if relationships defined)

When one-to-many relationships are specified (e.g., Pipeline → PipelineRuns), create expandable parent tables that show children inline.

#### Expandable Row Behavior

- **Parent row:** Has an expand/collapse chevron icon (▶/▼) as the first cell
- **Collapsed state:** Shows only the parent resource row (default)
- **Expanded state:** Shows the parent row plus a nested child table indented below it
- **Child table:** Filtered to only show children belonging to that parent
- **No children:** Show italic text "No related <ChildKind>s" when expanded
- **Loading:** Show spinner in expanded area while fetching children

#### Visual Structure

```
┌─────────────────────────────────────────────────────────────────┐
│ ▶ │ pipeline-1      │ default   │ Ready   │ 2h ago  │ Actions │  ← collapsed
├─────────────────────────────────────────────────────────────────┤
│ ▼ │ pipeline-2      │ default   │ Ready   │ 1h ago  │ Actions │  ← expanded
│   └──────────────────────────────────────────────────────────── │
│     │ Name              │ Status    │ Started   │ Actions │     │  ← child table
│     │ pipeline-2-run-1  │ Succeeded │ 30m ago   │ ...     │     │
│     │ pipeline-2-run-2  │ Running   │ 5m ago    │ ...     │     │
├─────────────────────────────────────────────────────────────────┤
│ ▶ │ pipeline-3      │ prod      │ Ready   │ 3h ago  │ Actions │
└─────────────────────────────────────────────────────────────────┘
```

#### Create `src/components/ExpandableResourceTable.tsx` (shared)

If not already present, create a shared expandable table component:

```tsx
interface ExpandableResourceTableProps {
  columns: Array<{ title: string; width?: string }>;
  rows: Array<{
    key: string;
    cells: React.ReactNode[];
    isExpanded: boolean;
    onToggle: () => void;
    expandedContent: React.ReactNode;
  }>;
  loading?: boolean;
  error?: string;
  emptyStateTitle?: string;
  emptyStateBody?: string;
  selectedProject?: string;
  'data-test'?: string;
}
```

#### Structure:
- First column is always the **expand toggle** (▶/▼ chevron icon)
- Use `AngleRightIcon` / `AngleDownIcon` from `@patternfly/react-icons`
- Toggle button: `<Button variant="plain" onClick={onToggle}><Icon /></Button>`
- Expanded row spans all columns: `<tr><td colSpan={columns.length + 1}>...</td></tr>`

#### Create child table components

For each relationship, the expanded content renders a **child table** filtered to that parent:

```tsx
// Example: ExpandedPipelineRunsTable.tsx
interface Props {
  parentName: string;
  parentNamespace?: string;
}

const ExpandedPipelineRunsTable: React.FC<Props> = ({ parentName, parentNamespace }) => {
  // Fetch children filtered by parent
  const [children, loaded, error] = useK8sWatchResource<ChildResource[]>({
    groupVersionKind: ChildGroupVersionKind,
    namespace: parentNamespace,
    isList: true,
  });

  // Filter by matchField (e.g., spec.pipelineRef.name === parentName)
  const filtered = React.useMemo(() => {
    if (!children) return [];
    return children.filter(child => {
      // matchType: "field" -> check spec.pipelineRef.name
      // matchType: "ownerRef" -> check metadata.ownerReferences
      // matchType: "label" -> check metadata.labels
      return getFieldValue(child, matchField) === parentName;
    });
  }, [children, parentName]);

  if (!loaded) return <Spinner size="md" />;
  if (error) return <Alert variant="warning" isInline title="Error loading children" />;
  if (filtered.length === 0) return <em>No related {childDisplayName}s</em>;

  return <ResourceTable columns={childColumns} rows={buildChildRows(filtered)} />;
};
```

#### Update parent table to use ExpandableResourceTable

Replace `ResourceTable` with `ExpandableResourceTable` for parent kinds that have children:

```tsx
const [expandedRows, setExpandedRows] = React.useState<Set<string>>(new Set());

const rows = parentResources.map(parent => ({
  key: parent.metadata?.uid || parent.metadata?.name || '',
  cells: [/* ... parent cells ... */],
  isExpanded: expandedRows.has(parent.metadata?.uid || ''),
  onToggle: () => {
    setExpandedRows(prev => {
      const next = new Set(prev);
      const key = parent.metadata?.uid || '';
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  },
  expandedContent: (
    <ExpandedChildTable
      parentName={parent.metadata?.name || ''}
      parentNamespace={parent.metadata?.namespace}
    />
  ),
}));
```

### Step 7 — CSS (`src/components/<operator-short-name>.css`)

Add only missing classes. Use **PatternFly variables only** (no hex). **Required classes:**

**Page Layout:**
```css
.console-plugin-template__inspect-page {
  padding: var(--pf-t--global--spacer--lg) var(--pf-t--global--spacer--xl);
}

.console-plugin-template__dashboard-cards {
  display: flex;
  flex-direction: column;
  gap: var(--pf-t--global--spacer--xl);
}

.console-plugin-template__resource-card {
  margin-bottom: 0;
}
```

**Table Structure (replaces OpenShift console classes):**
```css
.console-plugin-template__resource-table {
  overflow: hidden;
}

.console-plugin-template__table-responsive {
  overflow-x: auto;
}

.console-plugin-template__table {
  border-collapse: collapse;
  width: 100%;
  background-color: var(--pf-t--global--background--color--primary--default);
}

.console-plugin-template__table-th {
  padding: var(--pf-t--global--spacer--sm) var(--pf-t--global--spacer--md);
  text-align: left;
  vertical-align: middle;
  background-color: var(--pf-t--global--background--color--secondary--default);
  border-bottom: 1px solid var(--pf-t--global--border--color--default);
  font-weight: var(--pf-t--global--font--weight--body--bold);
}

.console-plugin-template__table-tr {
  border-bottom: 1px solid var(--pf-t--global--border--color--default);
}

.console-plugin-template__table-tr:hover {
  background-color: var(--pf-t--global--background--color--secondary--hover);
}

.console-plugin-template__table-td {
  padding: var(--pf-t--global--spacer--sm) var(--pf-t--global--spacer--md);
  text-align: left;
  vertical-align: middle;
  word-wrap: break-word;
  overflow: hidden;
}

.console-plugin-template__table-message {
  padding: var(--pf-t--global--spacer--lg);
}
```

**Loading Spinner (three-dot animated loader):**
```css
.console-plugin-template__loader {
  display: flex;
  gap: var(--pf-t--global--spacer--sm);
  align-items: center;
  justify-content: center;
  padding: var(--pf-t--global--spacer--lg);
}

.console-plugin-template__loader-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background-color: var(--pf-t--global--color--brand--default);
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

**Action Buttons:**
```css
.console-plugin-template__action-buttons {
  display: flex;
  gap: var(--pf-t--global--spacer--xs);
  flex-wrap: nowrap;
}

.console-plugin-template__action-inspect {
  flex-shrink: 0;
}

.console-plugin-template__action-delete {
  flex-shrink: 0;
}
```

**Important:** Button colors come from PatternFly's `variant` prop (`variant="primary"` for blue Inspect button, `variant="danger"` for red Delete button). Do NOT add custom background-color/border-color CSS for buttons. The action- classes are only for layout (flex-shrink), not colors.

**Expandable Rows (if relationships defined):**
```css
.console-plugin-template__expand-toggle {
  width: 32px;
  padding: 0;
}

.console-plugin-template__expanded-row {
  background-color: var(--pf-t--global--background--color--secondary--default);
}

.console-plugin-template__expanded-content {
  padding: var(--pf-t--global--spacer--md) var(--pf-t--global--spacer--lg);
  padding-left: var(--pf-t--global--spacer--2xl);
}

.console-plugin-template__child-table {
  background-color: var(--pf-t--global--background--color--primary--default);
  border: 1px solid var(--pf-t--global--border--color--default);
  border-radius: var(--pf-t--global--border--radius--small);
}

.console-plugin-template__no-children {
  font-style: italic;
  color: var(--pf-t--global--color--nonstatus--gray--default);
  padding: var(--pf-t--global--spacer--sm);
}
```

**Critical:** Never use `co-m-*`, `table-hover`, or inline `style` attributes. All styling via CSS classes with PatternFly variables. Keyframes names must be **kebab-case**.

### Step 7b — Optional: Overview dashboard

Optional summary count cards above tables. Component that uses `useK8sWatchResource` per kind and shows counts; Grid + Card; PF variables and `console-plugin-template__` prefix.

### Step 8 — Operator page (`src/<OperatorShortName>Page.tsx`)

**Imports:** Add `Title` and `Spinner` from `@patternfly/react-core`.

**Structure with proper visual hierarchy:**

```tsx
import { Title, Card, CardTitle, CardBody, Spinner } from '@patternfly/react-core';

export const MyOperatorPage: React.FC = () => {
  const { t } = useTranslation('plugin__console-plugin-template');
  const [activeNamespace] = useActiveNamespace();
  const operatorStatus = useOperatorDetection(MY_OPERATOR_INFO);

  const selectedProject = activeNamespace === '#ALL_NS#' ? '#ALL_NS#' : activeNamespace;
  const pageTitle = t('My Operator');

  // Loading state
  if (operatorStatus === 'loading') {
    return (
      <>
        <Helmet><title>{pageTitle}</title></Helmet>
        <div className="console-plugin-template__inspect-page">
          <Spinner size="lg" aria-label={t('Loading...')} />
        </div>
      </>
    );
  }

  // Not installed state
  if (operatorStatus === 'not-installed') {
    return (
      <>
        <Helmet><title>{pageTitle}</title></Helmet>
        <div className="console-plugin-template__inspect-page">
          <Title headingLevel="h1" size="xl">
            {pageTitle}
          </Title>
          <OperatorNotInstalled operatorDisplayName={MY_OPERATOR_INFO.displayName} />
        </div>
      </>
    );
  }

  // Main dashboard
  return (
    <>
      <Helmet><title>{pageTitle}</title></Helmet>
      <div className="console-plugin-template__inspect-page">
        <Title
          headingLevel="h1"
          size="xl"
          style={{ marginBottom: 'var(--pf-t--global--spacer--lg)' }}
        >
          {pageTitle}
        </Title>

        {/* Fixed namespace info alert (only if operator has a fixed namespace) */}
        {/* Example for NFD which uses openshift-nfd namespace */}
        <Alert
          variant="info"
          isInline
          title={t('Fixed Namespace')}
          style={{ marginBottom: 'var(--pf-t--global--spacer--md)' }}
        >
          {t('All <OperatorName> resources are managed in the <namespace> namespace.')}
        </Alert>

        <div className="console-plugin-template__dashboard-cards">
          <Card className="console-plugin-template__resource-card">
            <CardTitle>{t('My Resources')}</CardTitle>
            <CardBody>
              <MyResourcesTable selectedProject={selectedProject} />
            </CardBody>
          </Card>
          {/* Repeat Card for each resource kind */}
        </div>
      </div>
    </>
  );
};

export default MyOperatorPage;
```

**Critical requirements:**
- Use **`#ALL_NS#`** (not `'all'`) when comparing `activeNamespace`.
- Wrap all states in `console-plugin-template__inspect-page` for proper padding.
- Add prominent **`<Title>`** at the top with bottom margin.
- **Fixed namespace operators:** If the operator uses a fixed namespace (e.g., `openshift-nfd`), add an info `<Alert>` below the title to inform users. Import `Alert` from `@patternfly/react-core`.
- Nest Cards inside `console-plugin-template__dashboard-cards` for vertical spacing.
- Pass **`selectedProject`** only to namespaced tables. For fixed-namespace operators, pass the fixed namespace value directly instead of `selectedProject`.
- Export both named (`export const`) and default (`export default`).

### Step 9 — `src/ResourceInspect.tsx` (extend only)

**Do not rewrite.** The file already implements the resource detail dashboard (Card + Grid, back button, Metadata/Labels/Annotations/Spec/Status/Events, optional sensitive-data toggle). When adding a new operator:

1. **DISPLAY_NAMES:** add `plural: 'Display Name'` for each new resource.
2. **getResourceModel(resourceType):** add cases returning the new kind’s K8sModel.
3. **getPagePath(resourceType):** add case returning the operator page path (e.g. `'/cert-manager'`) or extend if multi-operator.

Cluster-scoped: component already handles 2-segment path (plural/name). Keep URL parsing and layout as-is.

### Step 10 — `console-extensions.json`

- **Routes:** Append page route (`exact: true`, path `/<operator-short-name>`, component **`$codeRef` in `moduleName.exportName` form**) and inspect route (`exact: false`, path `["/<operator-short-name>/inspect"]`, component same form).
- **Component `$codeRef` format (required):** Use **named-export** form so the build does not fail with "Invalid module export 'default'". For the operator page use `"component": { "$codeRef": "<OperatorShortName>Page.<OperatorShortName>Page" }` (e.g. `"CertManagerPage.CertManagerPage"`). For the inspect route use `"component": { "$codeRef": "ResourceInspect.ResourceInspect" }`. Never use only the module name (e.g. `"CertManagerPage"`), as that is resolved as the default export and triggers the ExtensionValidator error.
- **Plugins section:** If missing, add `console.navigation/section` with `id: "plugins"`, `insertAfter: "observe"`. Add nav link only if not present: `console.navigation/href` with `id: "<operator-short-name>"`, `href: "/<operator-short-name>"`, **`section: "plugins"`**.

### Step 11 — `package.json`

Add to `consolePlugin.exposedModules`: `"<OperatorShortName>Page": "./<OperatorShortName>Page"`. Add `"ResourceInspect": "./ResourceInspect"` only if not already present.

### Step 12 — Locales

Add all new strings to `locales/en/plugin__console-plugin-template.json` (page title, resource display names, empty states, Actions, Inspect, Delete, error messages, etc.). Do not remove existing keys. Include "Plugins" if you added the section.

### Step 13 — RBAC

In `charts/openshift-console-plugin/templates/rbac-clusterroles.yaml`, add or append ClusterRoles (and bindings): Reader (get, list, watch) and Admin (get, list, watch, delete) for the new API groups/resources. Use template name `{{ template "openshift-console-plugin.name" . }}-<operator-short-name>-reader` and `-admin`.

---

## Validation

- **Before coding:** Confirm `oc api-resources | grep -i <keyword>` output has been obtained and used for all API groups, versions, and namespaced/cluster-scoped classification.
- Run **`yarn build-dev`**. It must succeed (ignore pre-existing `node_modules` errors). If you see **"Invalid module export 'default' in extension [N] property 'component'"**, fix `console-extensions.json`: change each route `component` `$codeRef` from `"ModuleName"` to `"ModuleName.ExportName"` (e.g. `CertManagerPage.CertManagerPage`).
- Run **`yarn lint`** (eslint + stylelint). Fix any issues in `src/` or CSS.
- **Runtime check:** Navigate to `/<operator-short-name>` in the console. If it shows "Operator not installed" when the operator is installed, the API group or version is wrong. Re-run `oc api-resources` and compare with the values used in the CRD models and `useOperatorDetection`.

---

## Definition of Done

**Functionality:**
- [ ] API groups and namespaced/cluster-scoped scope confirmed via **`oc api-resources | grep -i <keyword>`** before any code was written; `APIVERSION` column values used in all CRD models.
- [ ] Operator detected via **useK8sModel** (not consoleFetchJSON).
- [ ] Plugins section exists; operator link under **Plugins** with **section: "plugins"**.
- [ ] Dashboard at `/<operator-short-name>` with **ResourceTable** in Cards, wrapped in **dashboard-cards** (gap), **left-aligned** table data.
- [ ] Inspect and Delete are **buttons** (sky blue and red); **ResourceTableRowActions** used so delete modal works per row.
- [ ] Inspect opens ResourceInspect at `/<operator-short-name>/inspect/...` with Metadata, Labels, Annotations, Spec, Status, Events (Card + Grid, back button).
- [ ] ResourceInspect extended with new DISPLAY_NAMES, getResourceModel, getPagePath (no layout rewrite).
- [ ] **Route components in `console-extensions.json`** use `$codeRef` as **`moduleName.exportName`** (e.g. `CertManagerPage.CertManagerPage`, `ResourceInspect.ResourceInspect`); no "Invalid module export 'default'" on build.
- [ ] Locales and RBAC updated; `yarn build-dev` and `yarn lint` pass.
- [ ] **If relationships defined:** Expandable rows work on parent tables; clicking expand shows filtered child resources inline; children lazy-loaded (fetched only when expanded).
- [ ] **If fixed namespace:** Info `<Alert>` displayed below page title informing users of the fixed namespace (e.g., "All NFD resources are managed in the openshift-nfd namespace").

**Styling & Visual Quality:**
- [ ] Page has visible **`<Title>`** component at top with proper spacing (`headingLevel="h1"`, `size="xl"`).
- [ ] All page states (loading, not-installed, main) wrapped in `console-plugin-template__inspect-page` for proper padding.
- [ ] Loading state uses `<Spinner>` from PatternFly (not custom loader for page-level).
- [ ] All table navigation uses **`<Link to>`** from react-router-dom (no `<a href>` or `window.location.href`).
- [ ] Tables use **plugin-prefixed CSS classes** (`console-plugin-template__table`, `__table-th`, `__table-td`, `__table-tr`), not OpenShift classes (`co-m-*`, `table`, `table-hover`).
- [ ] Table headers and cells use **CSS classes** (no inline `style` attributes for padding/alignment).
- [ ] Empty states use new PatternFly API (`titleText` prop, `icon={SearchIcon}`, not separate `<Title>` component).
- [ ] CSS file includes all required classes: page layout, table structure, loader, action buttons (see Step 7).
- [ ] No hex colors; no `.pf-`/`.co-` custom structure; keyframes kebab-case.
- [ ] Action buttons use `console-plugin-template__action-buttons` wrapper with proper flex layout.
- [ ] Button className on `<Button>` component (not on wrapping `<Link>`); colors from `variant` prop only.
- [ ] Dashboard cards have vertical spacing via `gap` in `console-plugin-template__dashboard-cards` wrapper.

---

## Final Response Format

1. **Files changed** (created/updated).
2. **CRDs/resources** used (and any inferred values).
3. **Validation** (build + lint).
4. **Assumptions / risks.**

---

## Quick Reference: Styling Patterns

**Page Structure:**
```tsx
// ✅ Good: Proper layout with Title
<div className="console-plugin-template__inspect-page">
  <Title headingLevel="h1" size="xl"
         style={{ marginBottom: 'var(--pf-t--global--spacer--lg)' }}>
    {pageTitle}
  </Title>
  <div className="console-plugin-template__dashboard-cards">
    <Card>...</Card>
  </div>
</div>

// ❌ Bad: No wrapper, no title
<div className="console-plugin-template__dashboard-cards">
  <Card>...</Card>
</div>
```

**Navigation:**
```tsx
// ✅ Good: React Router Link
import { Link } from 'react-router-dom';
<Link to={inspectHref}>{name}</Link>

// ❌ Bad: Full page reload
<a href={inspectHref}>{name}</a>
window.location.href = inspectHref;
```

**Action Buttons:**
```tsx
// ✅ Good: className on Button, variant for colors
<div className="console-plugin-template__action-buttons">
  <Link to={inspectHref}>
    <Button className="console-plugin-template__action-inspect" variant="primary" size="sm">
      {t('Inspect')}
    </Button>
  </Link>
  <Button
    className="console-plugin-template__action-delete"
    variant="danger"
    size="sm"
    onClick={launchDeleteModal}
  >
    {t('Delete')}
  </Button>
</div>

// ❌ Bad: className on Link wrapper
<div className="console-plugin-template__action-buttons">
  <Link to={inspectHref} className="console-plugin-template__action-inspect">
    <Button variant="primary" size="sm">  {/* Missing className! */}
      {t('Inspect')}
    </Button>
  </Link>
</div>

// ❌ Bad: Custom color CSS instead of variant
<Button className="my-custom-button">  {/* Wrong approach */}
/* CSS: .my-custom-button { background-color: #0066cc; } */
```

**Table Classes:**
```tsx
// ✅ Good: Plugin-prefixed classes
<div className="console-plugin-template__resource-table">
  <div className="console-plugin-template__table-responsive">
    <table className="console-plugin-template__table">
      <thead>
        <tr>
          <th className="console-plugin-template__table-th">Name</th>
        </tr>
      </thead>
      <tbody>
        <tr className="console-plugin-template__table-tr">
          <td className="console-plugin-template__table-td">value</td>
        </tr>
      </tbody>
    </table>
  </div>
</div>

// ❌ Bad: OpenShift console classes
<div className="co-m-table-grid co-m-table-grid--bordered">
  <div className="table-responsive">
    <table className="table table-hover">
      <th style={{ padding: '1rem' }}>Name</th>  {/* inline styles */}
    </table>
  </div>
</div>
```

**Loading States:**
```tsx
// ✅ Good: Page-level Spinner
if (operatorStatus === 'loading') {
  return (
    <div className="console-plugin-template__inspect-page">
      <Spinner size="lg" aria-label={t('Loading...')} />
    </div>
  );
}

// ✅ Good: Table-level loader
if (loading) {
  return (
    <div className="console-plugin-template__loader">
      <div className="console-plugin-template__loader-dot"></div>
      <div className="console-plugin-template__loader-dot"></div>
      <div className="console-plugin-template__loader-dot"></div>
    </div>
  );
}

// ❌ Bad: Console classes
<div className="co-m-loader co-an-fade-in-out">
  <div className="co-m-loader-dot__one"></div>
</div>
```

**Empty States:**
```tsx
// ✅ Good: PatternFly 6 API
<EmptyState
  titleText={emptyStateTitle || t('No resources found')}
  icon={SearchIcon}
  headingLevel="h4"
>
  <EmptyStateBody>{emptyStateBody}</EmptyStateBody>
</EmptyState>

// ❌ Bad: Old API with separate Title
<EmptyState>
  <SearchIcon className="co-m-empty-state__icon" />
  <Title size="lg" headingLevel="h4">{title}</Title>
  <EmptyStateBody>{body}</EmptyStateBody>
</EmptyState>
```

**CSS Variables:**
```css
/* ✅ Good: PatternFly variables */
.console-plugin-template__table {
  background-color: var(--pf-t--global--background--color--primary--default);
  padding: var(--pf-t--global--spacer--md);
}

/* ❌ Bad: Hex colors, no prefix */
.my-table {
  background-color: #ffffff;
  padding: 16px;
}
```
