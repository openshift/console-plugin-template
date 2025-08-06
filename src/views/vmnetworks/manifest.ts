import { EncodedExtension } from '@openshift/dynamic-plugin-sdk-webpack';
import { HrefNavItem, RoutePage } from '@openshift-console/dynamic-plugin-sdk';
import { ConsolePluginBuildMetadata } from '@openshift-console/dynamic-plugin-sdk-webpack/lib/build-types';

export const VMNetworksExtensions: EncodedExtension[] = [
  {
    properties: {
      dataAttributes: {
        'data-quickstart-id': 'qs-nav-vmnetwork',
        'data-test-id': 'vmnetwork-nav-item',
      },
      href: 'k8s/cluster/virtualmachine-networks',
      id: 'vmnetwork-virt-perspective',
      insertBefore: 'networkpolicies-virt-perspective',
      name: '%plugin__networking-console-plugin~VirtualMachine networks%',
      perspective: 'virtualization-perspective',
      prefixNamespaced: false,
      section: 'networking-virt-perspective',
    },
    type: 'console.navigation/href',
  } as EncodedExtension<HrefNavItem>,

  {
    properties: {
      dataAttributes: {
        'data-quickstart-id': 'qs-nav-vmnetwork',
        'data-test-id': 'vmnetwork-nav-item',
      },
      href: 'k8s/cluster/virtualmachine-networks',
      id: 'vmnetwork',
      insertBefore: 'networkPolicies',
      name: '%plugin__networking-console-plugin~VirtualMachine networks%',
      prefixNamespaced: false,
      section: 'networking',
    },
    type: 'console.navigation/href',
  } as EncodedExtension<HrefNavItem>,
  {
    properties: {
      component: {
        $codeRef: 'VMNetworkList',
      },
      path: ['/k8s/cluster/virtualmachine-networks'],
    },
    type: 'console.page/route',
  } as EncodedExtension<RoutePage>,
];

export const VMNetworksExposedModules: ConsolePluginBuildMetadata['exposedModules'] = {
  VMNetworkList: './views/vmnetworks/list/VMNetworkList.tsx',
};
