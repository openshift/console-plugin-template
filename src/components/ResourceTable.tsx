import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { EmptyState, EmptyStateBody, Alert, AlertVariant, Spinner } from '@patternfly/react-core';
import { SearchIcon } from '@patternfly/react-icons';

interface Column {
  title: string;
  width?: number;
}

interface Row {
  cells: React.ReactNode[];
}

interface ResourceTableProps {
  columns: Column[];
  rows: Row[];
  loading?: boolean;
  error?: string;
  emptyStateTitle?: string;
  emptyStateBody?: string;
  selectedProject?: string;
  'data-test'?: string;
}

export const ResourceTable: React.FC<ResourceTableProps> = ({
  columns,
  rows,
  loading = false,
  error,
  emptyStateTitle,
  emptyStateBody,
  selectedProject,
  'data-test': dataTest,
}) => {
  const { t } = useTranslation('plugin__console-plugin-template');

  const defaultEmptyStateBody =
    selectedProject && selectedProject !== 'all'
      ? t('No resources of this type are currently available in project {{project}}.', {
          project: selectedProject,
        })
      : t('No resources of this type are currently available in the demo project.');

  if (loading) {
    return (
      <div className="console-plugin-template__loader" data-test={`${dataTest}-loading`}>
        <Spinner size="lg" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="console-plugin-template__table-message" data-test={`${dataTest}-error`}>
        <Alert variant={AlertVariant.danger} title={t('Error loading resources')} isInline>
          {error}
        </Alert>
      </div>
    );
  }

  if (rows.length === 0) {
    return (
      <div className="console-plugin-template__table-message" data-test={`${dataTest}-empty`}>
        <EmptyState
          titleText={emptyStateTitle || t('No resources found')}
          icon={SearchIcon}
          headingLevel="h4"
        >
          <EmptyStateBody>{emptyStateBody ?? defaultEmptyStateBody}</EmptyStateBody>
        </EmptyState>
      </div>
    );
  }

  const totalSpecifiedWidth = columns.reduce((sum, col) => sum + (col.width || 0), 0);
  const hasSpecifiedWidths = totalSpecifiedWidth > 0;
  const defaultWidth = hasSpecifiedWidths ? undefined : 100 / columns.length;

  return (
    <div className="console-plugin-template__resource-table" data-test={dataTest}>
      <div className="console-plugin-template__table-responsive">
        <table className="console-plugin-template__table">
          <thead>
            <tr>
              {columns.map((column, index) => {
                const width = hasSpecifiedWidths ? `${column.width || 0}%` : `${defaultWidth}%`;

                return (
                  <th
                    key={index}
                    className="console-plugin-template__table-th"
                    role="columnheader"
                    style={{ width }}
                  >
                    {column.title}
                  </th>
                );
              })}
            </tr>
          </thead>
          <tbody>
            {rows.map((row, rowIndex) => (
              <tr key={rowIndex} className="console-plugin-template__table-tr">
                {row.cells.map((cell, cellIndex) => (
                  <td key={cellIndex} className="console-plugin-template__table-td">
                    {cell}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};
