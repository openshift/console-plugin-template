
# Add a New Operator to the OpenShift Console Plugin

Copy the template, fill in operator details, run it. Works on a clean repo (after `git stash`) or with existing operators already added.

---

## End Goal

- **Operator dashboard** at `/<operator-short-name>`: page title plus one **Card + table per resource kind**. Tables use the shared **ResourceTable** component (see [Existing shared components](#existing-shared-components)).
- **Sidebar:** The dashboard link appears under **Plugins** in the admin perspective. If the Plugins section does not exist, create it first; then add the operator link. Do not duplicate the section or the link if they already exist.
- **Per-row actions:** Each custom resource row has an **Inspect** button (navigates to the resource detail page) and a **Delete** button (opens confirmation modal). Both must be **buttons** (not link-styled only): Inspect with a sky-blue background, Delete with a red background.
- **Resource detail dashboard (inspect page):** Clicking Inspect opens `/<operator-short-name>/inspect/<plural>/[namespace/]<name>`. The **ResourceInspect** component (see [Existing shared components](#existing-shared-components)) shows Metadata, Labels, Annotations, Specification, Status, and Events in a **Card + Grid** layout with a back button—no tabs. When adding a new operator, **extend** ResourceInspect's maps and models; do not replace its layout or structure.
- **Optional:** Overview dashboard (summary count cards above tables) per Step 7b. Not required.
- **Expandable rows (one-to-many relationships):** Parent resources can have expandable rows showing related child resources inline. When a relationship is defined, the parent table row has an expand/collapse toggle; expanding reveals a nested table of child resources filtered by that parent. See **Step 6b** for implementation details.

---

## Existing Shared Components

The project already includes:

- **`src/components/ResourceTable.tsx`** — Shared table: accepts `columns` (title, optional width), `rows` (cells as React nodes), `loading`, `error`, `emptyStateTitle`, `emptyStateBody`, `selectedProject`, `data-test`. Renders a plain `<table>` with thead/tbody, loading (three-dot loader), error Alert, empty EmptyState, or data rows. Use this for **all** operator resource tables; do not use VirtualizedTable for the dashboard tables.
- **`ResourceTableRowActions`** (exported from the same file) — Renders Inspect + Delete **buttons** for one row. Accepts `resource: K8sResourceCommon` and `inspectHref: string`. Use it in the Actions cell of each row so `useDeleteModal` is called per row (hooks cannot be called inside `.map()`).
- **`src/ResourceInspect.tsx`** — Shared resource detail page: Card + Grid layout, back button, Metadata/Labels/Annotations/Spec/Status/Events cards, optional "Show/Hide sensitive data" for spec/status. When adding a new operator, **add** entries to `DISPLAY_NAMES`, `getResourceModel(resourceType)`, and `getPagePath(resourceType)`; do not rewrite the component or change its layout/styling pattern.

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

Follow the implementation specification in this document exactly.
Start implementation immediately. Do not ask for confirmation.
If any input is missing, infer from upstream CRD docs and record inferences in the final summary.
```

---

## What NOT to Do

- **Do NOT misuse `useK8sModel` return value.** The hook returns `[model, inFlight]` where `inFlight` is `true` **while loading** and `false` when complete. A common mistake is naming the second parameter `loaded` and checking `if (!loaded) return 'loading'` — this is **backwards** because `!inFlight` is `false` during loading, causing the check to be skipped. The page will either be stuck loading forever or immediately show "not installed". **Correct pattern:** `if (inFlight) return 'loading'`.
- **Do NOT use `consoleFetchJSON`** for operator/CRD detection; use `useK8sModel` only.
- **Do NOT use VirtualizedTable** for the operator dashboard resource tables; use **ResourceTable** with `columns` and `rows`.
- **Do NOT call `useDeleteModal` inside a `.map()` callback.** Use a per-row component (e.g. `ResourceTableRowActions`) that receives the resource and calls `useDeleteModal(resource)`.
- **Do NOT use link-styled-only actions:** Inspect and Delete must be real **buttons** (Inspect = sky blue background, Delete = red). Style them with PatternFly CSS variables in the shared CSS (e.g. `--pf-v6-global--palette--blue-400`, `--pf-v6-global--palette--red-500`).
- **Do NOT use hex colors** (e.g. `#1e1e1e`, `#374151`) in CSS or inline styles. Use **PatternFly CSS variables only** (e.g. `var(--pf-v6-global--BackgroundColor--200)`, `var(--pf-v6-global--BorderColor--100)`).
- **Do NOT use `.pf-` or `.co-` prefixed class names** for your own structure (e.g. `co-m-loader`, `co-m-pane__body`). Use **`console-plugin-template__`** prefix for all custom classes.
- **Do NOT use PatternFly 6 `EmptyStateHeader` or `EmptyStateIcon`**; they do not exist. Use props on `<EmptyState>`: `titleText`, `icon={SearchIcon}`, `headingLevel`.
- **Do NOT use `Label`'s `variant` prop for status colors.** Use the **`status`** prop: `status="success"` (green), `status="danger"` (red), `status="warning"` (orange). (`variant` is for outline/filled/overflow/add.)
- **Do NOT use `PageSection variant="light"`**; use `"default"` or `"secondary"`.
- **Do NOT assume `useActiveNamespace()` returns `'all'`** when all namespaces are selected; it returns **`#ALL_NS#`**.
- **Do NOT create two separate routes for inspect** (e.g. one for namespaced and one for cluster-scoped). Use **one** route with `path: ["/<operator-short-name>/inspect"]` and `exact: false`; the component parses the rest of the path.
- **Do NOT put the operator dashboard link under `section: "home"`.** It must be **`section: "plugins"`** so it appears under Plugins.
- **Do NOT rely on margin alone for spacing between table cards** if it collapses. Use a **wrapper div** with `display: flex`, `flex-direction: column`, and **`gap`** (e.g. `console-plugin-template__dashboard-cards`).
- **Do NOT add `titleFormat` to table column config** when using the SDK's `TableColumn` type elsewhere; it is not part of that type. For ResourceTable, columns only have `title` and optional `width`.
- **Do NOT rewrite `ResourceInspect.tsx`** when adding an operator. Extend its `DISPLAY_NAMES`, `getResourceModel`, and `getPagePath`; keep the existing Card + Grid layout and back button.
- **Do NOT fetch all children upfront for expandable rows.** Fetch children only when the row is expanded (lazy loading). Use a separate `useK8sWatchResource` call inside the expanded row component.
- **Do NOT use PatternFly's `<Table>` with `expandable` variant** for the main dashboard tables. Use the custom expandable row pattern with `ResourceTable` to maintain consistency.
- **Do NOT hardcode parent-child matching logic.** Use the `matchType` and `matchField` from the relationship config to filter children dynamically.

---

## Critical Rules (read before coding)

1. **Operator detection:** Use **`useK8sModel`** only. `consoleFetchJSON` to CRD/API-group endpoints fails silently due to RBAC in the console proxy. **IMPORTANT:** `useK8sModel` returns `[model, inFlight]` where `inFlight` is `true` **while loading**. Check `if (inFlight) return 'loading'` — NOT `if (!inFlight)`.
2. **EmptyState (PatternFly 6):** Use `<EmptyState titleText="..." icon={SearchIcon} headingLevel="h2"><EmptyStateBody>...</EmptyStateBody></EmptyState>`.
3. **`useActiveNamespace`** returns **`#ALL_NS#`** when all namespaces are selected (not `'all'`).
4. **Inspect route:** Single route with `path: ["/<operator-short-name>/inspect"]`, `exact: false`. Component parses path segments internally.
5. **Navigation:** Operator link under **Plugins** (`section: "plugins"`). Create Plugins section first if missing; do not duplicate section or link.
6. **`useK8sWatchResource`:** Use the **`groupVersionKind`** object (`{ group, version, kind }`), not the deprecated `kind` string.
7. **CSS:** Only PatternFly CSS variables; no hex. Prefix all custom classes with **`console-plugin-template__`**. No naked element selectors that could affect console globally; scope under your classes. **Keyframes names** must be kebab-case (e.g. `console-plugin-template-loader-bounce`).
8. **i18n namespace:** **`plugin__console-plugin-template`**.
9. **Cluster-scoped resources:** No Namespace column, no `selectedProject` on the table, inspect URL has 2 segments (`/<plural>/<name>`), no `/namespaces/<ns>/` in delete path.

---

## Read-First Files

| File | Purpose |
|------|--------|
| `src/components/ResourceTable.tsx` | Shared table API (columns, rows, loading, error, empty); `ResourceTableRowActions` for Inspect/Delete |
| `src/components/ExpandableResourceTable.tsx` | Shared expandable table for parent-child relationships (create if relationships defined) |
| `src/ResourceInspect.tsx` | Shared inspect page (Card + Grid, back button); extend DISPLAY_NAMES, getResourceModel, getPagePath |
| `src/hooks/useOperatorDetection.ts` | Operator CRD detection hook |
| `src/components/crds/index.ts` | K8sModel and TS interfaces per kind |
| `src/components/crds/Events.ts` | plural → Kind for events |
| `src/components/OperatorNotInstalled.tsx` | Generic "not installed" empty state |
| `src/components/<operator-short-name>.css` | Shared operator CSS (cards, tables, buttons, inspect, expandable rows) |
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
2. **Optional:** Columns from CRD `additionalPrinterColumns` (priority 0; priority 1 only if total ≤ 8). Use each column's `jsonPath`; `type: date` → `<Timestamp>`; status/conditions → Label with **`status`** prop (success/danger/warning).
3. **Fallback** if no additionalPrinterColumns: Name, Namespace (if namespaced), Status (from `status.conditions[type=Ready]`), Age (`metadata.creationTimestamp`), Actions.
4. **Always last:** Actions column with **Inspect** button (sky blue) and **Delete** button (red), using **ResourceTableRowActions** so `useDeleteModal` is called per row.
5. User-provided column overrides (if any) override the above; document them in the summary.

---

## Implementation Steps

### Step 1 — Directories

```bash
mkdir -p src/hooks src/components/crds
```

### Step 2 — `src/hooks/useOperatorDetection.ts`

Use `useK8sModel` with `{ group, version, kind }` for the primary resource. Export `OperatorStatus`, `OperatorInfo`, `<OPERATOR>_OPERATOR_INFO`, and `useOperatorDetection()`. If the file exists, add the new operator's info and extend the hook.

**⚠️ CRITICAL: Correct `useK8sModel` usage:**
```typescript
export function useOperatorDetection(operatorInfo: OperatorInfo): OperatorStatus {
  const [model, inFlight] = useK8sModel({
    group: operatorInfo.group,
    version: operatorInfo.version,
    kind: operatorInfo.kind,
  });

  // inFlight is TRUE while loading, FALSE when complete
  if (inFlight) {
    return 'loading';
  }

  if (model) {
    return 'installed';
  }

  return 'not-installed';
}
```

### Step 3 — `src/components/crds/index.ts`

For each resource kind, export a **K8sModel** and a TypeScript interface extending `K8sResourceCommon` with optional `spec`/`status`. Append if the file exists.

### Step 4 — `src/components/crds/Events.ts`

Add `plural: 'Kind'` to **RESOURCE_TYPE_TO_KIND** for each new resource.

### Step 5 — `src/components/OperatorNotInstalled.tsx`

Create only if missing. Generic empty state with `EmptyState` (titleText, icon={SearchIcon}, headingLevel), `EmptyStateBody`, and operator display name message.

### Step 6 — Table components (`src/components/<KindPlural>Table.tsx`)

**Use ResourceTable.** One file per resource kind.

- Build **columns**: array of `{ title, width? }` (Name, Namespace if namespaced, then algorithm columns, then Actions).
- Build **rows**: from `useK8sWatchResource` list; each row's **cells** array includes Name (Link to inspect), Namespace if namespaced, Status (Label with **status** prop), Created (Timestamp), and **`<ResourceTableRowActions resource={obj} inspectHref={inspectHref} />`** for the Actions cell.
- Pass **loading** (`!loaded && !loadError`), **error** (`loadError?.message`), **emptyStateTitle**, **emptyStateBody**, **selectedProject** (namespaced only), **data-test**.
- **Namespaced:** `selectedProject`, inspect href `/<page>/inspect/<plural>/${namespace}/${name}`.
- **Cluster-scoped:** no `selectedProject`, inspect href `/<page>/inspect/<plural>/${name}`.

Do **not** use VirtualizedTable or call `useDeleteModal` inside `.map()`.

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

#### Parent table with expansion

Modify the parent table component to track expansion state:

```tsx
const [expandedRows, setExpandedRows] = React.useState<Set<string>>(new Set());

const toggleRow = (key: string) => {
  setExpandedRows(prev => {
    const next = new Set(prev);
    if (next.has(key)) next.delete(key);
    else next.add(key);
    return next;
  });
};

const rows = resources.map(obj => ({
  key: obj.metadata.uid,
  cells: [/* ... */],
  isExpanded: expandedRows.has(obj.metadata.uid),
  onToggle: () => toggleRow(obj.metadata.uid),
  expandedContent: (
    <ExpandedChildTable
      parentName={obj.metadata.name}
      parentNamespace={obj.metadata.namespace}
    />
  ),
}));
```

### Step 7 — CSS (`src/components/<operator-short-name>.css`)

Add only missing classes. Use **PatternFly variables only** (no hex). Include:

- `.console-plugin-template__resource-card` (margin or used in dashboard wrapper).
- Dashboard cards wrapper: `.console-plugin-template__dashboard-cards` with `display: flex`, `flex-direction: column`, **`gap: var(--pf-v6-global--spacer--xl)`** so tables are not stuck together. Cards inside can have `margin-bottom: 0`.
- Table styles for ResourceTable (header/data row background, borders, **text-align: left** for table data).
- Loader (e.g. `.console-plugin-template__loader`, `.console-plugin-template__loader-dot`). **Keyframes** names must be **kebab-case** (e.g. `console-plugin-template-loader-bounce`).
- Action buttons: `.console-plugin-template__action-inspect` (sky blue background/border), `.console-plugin-template__action-delete` (red), using `var(--pf-v6-global--palette--blue-400)`, `var(--pf-v6-global--palette--red-500)` (and hover variants).
- Expandable rows (if relationships defined):
  - `.console-plugin-template__expand-toggle`: button styling for expand/collapse chevron
  - `.console-plugin-template__expanded-row`: full-width cell containing child table
  - `.console-plugin-template__expanded-content`: padding and background for nested table area (`padding-left: var(--pf-v6-global--spacer--xl)`, subtle background)
  - `.console-plugin-template__child-table`: nested table styling (slightly smaller, indented)
  - `.console-plugin-template__no-children`: italic empty state text

Example CSS for expandable rows:
```css
.console-plugin-template__expand-toggle {
  background: transparent;
  border: none;
  cursor: pointer;
  padding: var(--pf-v6-global--spacer--xs);
  color: var(--pf-v6-global--Color--100);
}

.console-plugin-template__expand-toggle:hover {
  color: var(--pf-v6-global--primary-color--100);
}

.console-plugin-template__expanded-row > td {
  padding: 0;
  background-color: var(--pf-v6-global--BackgroundColor--200);
}

.console-plugin-template__expanded-content {
  padding: var(--pf-v6-global--spacer--md);
  padding-left: var(--pf-v6-global--spacer--2xl);
  border-left: 3px solid var(--pf-v6-global--primary-color--100);
}

.console-plugin-template__child-table {
  font-size: var(--pf-v6-global--FontSize--sm);
}

.console-plugin-template__no-children {
  font-style: italic;
  color: var(--pf-v6-global--Color--200);
  padding: var(--pf-v6-global--spacer--sm);
}
```

### Step 7b — Optional: Overview dashboard

Optional summary count cards above tables. Component that uses `useK8sWatchResource` per kind and shows counts; Grid + Card; PF variables and `console-plugin-template__` prefix.

### Step 8 — Operator page (`src/<OperatorShortName>Page.tsx`)

- Use **`#ALL_NS#`** (not `'all'`) to derive `selectedProject`.
- Loading: Spinner or shared loader.
- Not installed: Helmet, title, OperatorNotInstalled.
- Main view: Helmet, title, then a **wrapper div** with class `console-plugin-template__dashboard-cards` (flex, column, gap), containing one **Card** per resource kind; each Card has CardTitle and CardBody with the corresponding **Table** component. Pass **selectedProject** only to namespaced tables.

### Step 9 — `src/ResourceInspect.tsx` (extend only)

**Do not rewrite.** The file already implements the resource detail dashboard (Card + Grid, back button, Metadata/Labels/Annotations/Spec/Status/Events, optional sensitive-data toggle). When adding a new operator:

1. **DISPLAY_NAMES:** add `plural: 'Display Name'` for each new resource.
2. **getResourceModel(resourceType):** add cases returning the new kind's K8sModel.
3. **getPagePath(resourceType):** add case returning the operator page path (e.g. `'/cert-manager'`) or extend if multi-operator.

Cluster-scoped: component already handles 2-segment path (plural/name). Keep URL parsing and layout as-is.

### Step 10 — `console-extensions.json`

- **Routes:** Append page route (`exact: true`, path `/<operator-short-name>`, component `<OperatorShortName>Page`) and inspect route (`exact: false`, path `["/<operator-short-name>/inspect"]`, component `ResourceInspect.ResourceInspect`).
- **Plugins section:** If missing, add `console.navigation/section` with `id: "plugins"`, `insertAfter: "observe"`. Add nav link only if not present: `console.navigation/href` with `id: "<operator-short-name>"`, `href: "/<operator-short-name>"`, **`section: "plugins"`**.

### Step 11 — `package.json`

Add to `consolePlugin.exposedModules`: `"<OperatorShortName>Page": "./<OperatorShortName>Page"`. Add `"ResourceInspect": "./ResourceInspect"` only if not already present.

### Step 12 — Locales

Add all new strings to `locales/en/plugin__console-plugin-template.json` (page title, resource display names, empty states, Actions, Inspect, Delete, error messages, etc.). Do not remove existing keys. Include "Plugins" if you added the section.

### Step 13 — RBAC

In `charts/openshift-console-plugin/templates/rbac-clusterroles.yaml`, add or append ClusterRoles (and bindings): Reader (get, list, watch) and Admin (get, list, watch, delete) for the new API groups/resources. Use template name `{{ template "openshift-console-plugin.name" . }}-<operator-short-name>-reader` and `-admin`.

---

## Validation

- Run **`yarn build-dev`**. It must succeed (ignore pre-existing `node_modules` errors).
- Run **`yarn lint`** (eslint + stylelint). Fix any issues in `src/` or CSS.

---

## Definition of Done

- [ ] Operator detected via **useK8sModel** (not consoleFetchJSON).
- [ ] Plugins section exists; operator link under **Plugins** with **section: "plugins"**.
- [ ] Dashboard at `/<operator-short-name>` with **ResourceTable** in Cards, wrapped in **dashboard-cards** (gap), **left-aligned** table data.
- [ ] Inspect and Delete are **buttons** (sky blue and red); **ResourceTableRowActions** used so delete modal works per row.
- [ ] Inspect opens ResourceInspect at `/<operator-short-name>/inspect/...` with Metadata, Labels, Annotations, Spec, Status, Events (Card + Grid, back button).
- [ ] ResourceInspect extended with new DISPLAY_NAMES, getResourceModel, getPagePath (no layout rewrite).
- [ ] No hex colors; no `.pf-`/`.co-` custom structure; keyframes kebab-case.
- [ ] Locales and RBAC updated; `yarn build-dev` and `yarn lint` pass.
- [ ] **If relationships defined:** Expandable rows work on parent tables; clicking expand shows filtered child resources inline; lazy-loaded (children fetched only when expanded).

---

## Final Response Format

1. **Files changed** (created/updated).
2. **CRDs/resources** used (and any inferred values).
3. **Validation** (build + lint).
4. **Assumptions / risks.**
