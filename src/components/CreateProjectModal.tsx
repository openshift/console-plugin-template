import * as React from 'react';
import {
  Alert,
  Button,
  Form,
  FormAlert,
  FormGroup,
  Modal,
  ModalVariant,
  Spinner,
  TextArea,
  TextInput,
} from '@patternfly/react-core';
import { useTranslation } from 'react-i18next';
import { k8sCreateResource } from '@openshift-console/dynamic-plugin-sdk/lib/utils/k8s';
import { K8sModel } from '@openshift-console/dynamic-plugin-sdk/lib/api/common-types';

const CreateProjectModal: React.FC<{ closeModal: () => void }> = ({
  closeModal,
}) => {
  const { t } = useTranslation();
  const [name, setName] = React.useState('');
  const [displayName, setDisplayName] = React.useState('');
  const [description, setDescription] = React.useState('');
  const [inProgress, setInProgress] = React.useState(false);
  const [errorMessage, setErrorMessage] = React.useState('');

  const thenPromise = (res) => {
    setInProgress(false);
    setErrorMessage('');
    return res;
  };

  const catchError = (error) => {
    const err =
      error.message || t('public~An error occurred. Please try again.');
    setInProgress(false);
    setErrorMessage(err);
    return Promise.reject(err);
  };

  const handlePromise = (promise) => {
    setInProgress(true);

    return promise.then(
      (res) => thenPromise(res),
      (error) => catchError(error),
    );
  };

  const createProject = React.useCallback(async () => {
    const data = {
      metadata: {
        name,
      },
      displayName,
      description,
    };
    return k8sCreateResource({ model: ProjectRequestModel, data });
  }, [description, displayName, name]);

  const create = () => {
    handlePromise(createProject())
      .then(closeModal)
      .catch((err) => {
        // eslint-disable-next-line no-console
        console.error(`Failed to create Project:`, err);
      });
  };

  return (
    <Modal
      variant={ModalVariant.small}
      isOpen
      title={t('public~Create Project')}
      actions={
        inProgress
          ? [<Spinner key="foo" />]
          : [
              <Button key="create" variant="primary" onClick={create}>
                {t('public~Create')}
              </Button>,
              <Button key="cancel" variant="link" onClick={closeModal}>
                {t('public~Cancel')}
              </Button>,
            ]
      }
    >
      <Form>
        <FormGroup label={t('public~Name')} isRequired fieldId="input-name">
          <TextInput
            id="input-name"
            data-test="input-name"
            name="name"
            type="text"
            onChange={(e, v) => setName(v)}
            value={name || ''}
            autoFocus
            required
          />
        </FormGroup>
        <FormGroup
          label={t('public~Display name')}
          fieldId="input-display-name"
        >
          <TextInput
            id="input-display-name"
            name="displayName"
            type="text"
            onChange={(e, v) => setDisplayName(v)}
            value={displayName || ''}
          />
        </FormGroup>
        <FormGroup label={t('public~Description')} fieldId="input-description">
          <TextArea
            id="input-description"
            name="description"
            onChange={(e, v) => setDescription(v)}
            value={description || ''}
          />
        </FormGroup>
        {errorMessage && (
          <FormAlert>
            <Alert
              isInline
              variant="danger"
              title={t('An error occurred.')}
              data-test="alert-error"
            >
              {errorMessage}
            </Alert>
          </FormAlert>
        )}
      </Form>
    </Modal>
  );
};

const ProjectRequestModel: K8sModel = {
  apiVersion: 'v1',
  apiGroup: 'project.openshift.io',
  label: 'ProjectRequest',
  // t('public~ProjectRequest')
  labelKey: 'public~ProjectRequest',
  plural: 'projectrequests',
  abbr: '',
  kind: 'ProjectRequest',
  id: 'projectrequest',
  labelPlural: 'ProjectRequests',
  // t('public~ProjectRequests')
  labelPluralKey: 'public~ProjectRequests',
};

export default CreateProjectModal;
