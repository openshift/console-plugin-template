import * as React from 'react';
import Helmet from 'react-helmet';
import {
  Page,
  PageSection,
  Text,
  TextContent,
  TextVariants,
  Title,
} from '@patternfly/react-core';

export default function ExamplePage() {
  return (
    <>
      <Helmet>
        <title>Hello, Plugin!</title>
      </Helmet>
      <Page>
        <PageSection variant="light">
          <Title headingLevel="h1">Hello, Plugin!</Title>
        </PageSection>
        <PageSection variant="light">
          <TextContent>
            <Text component={TextVariants.p}>
              This is a custom page contributed by the template console plugin.
              The extension that adds the page is declared in
              console-extensions.json in the package root along with the
              corresponding nav item. Update console-extensions.json to change
              or add extensions.
            </Text>
            <Text component={TextVariants.p}>
              After cloning this project, replace references to
              <code>console-template-plugin</code> and other plugin metadata in
              the <code>package.json</code> and <code>manifest.yaml</code>
              files with values for your plugin.
            </Text>
          </TextContent>
        </PageSection>
      </Page>
    </>
  );
}
