import { DocumentTitle, ListPageHeader } from '@openshift-console/dynamic-plugin-sdk';
import { useTranslation } from 'react-i18next';
import { Content, PageSection } from '@patternfly/react-core';
import { CheckCircleIcon } from '@patternfly/react-icons';
import './example.css';

export default function ExamplePage() {
  const { t } = useTranslation('plugin__console-plugin-template');

  return (
    <>
      <DocumentTitle>{t('Hello, Plugin!')}</DocumentTitle>
      <ListPageHeader title={t('Hello, Plugin!')} />
      <PageSection>
        <Content component="p">
          <span className="console-plugin-template__nice">
            <CheckCircleIcon /> {t('Success!')}
          </span>{' '}
          {t('Your plugin is working.')}
        </Content>
        <Content component="p">
          {t(
            'This is a custom page contributed by the console plugin template. The extension that adds the page is declared in console-extensions.json in the project root along with the corresponding nav item. Update console-extensions.json to change or add extensions. Code references in console-extensions.json must have a corresponding property',
          )}
          <code>{t('exposedModules')}</code>{' '}
          {t('in package.json mapping the reference to the module.')}
        </Content>
        <Content component="p">
          {t('After cloning this project, replace references to')}{' '}
          <code>{t('console-template-plugin')}</code>{' '}
          {t('and other plugin metadata in package.json with values for your plugin.')}
        </Content>
      </PageSection>
    </>
  );
}
