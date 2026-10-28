import React from 'react';
import { addGlobalFill } from 'foremanReact/components/common/Fill/GlobalFill';
import NetboxCard from './src/Components/NetboxCard';
import NetboxSyncAction from './src/Components/NetboxSyncAction';

// show the card after the core "Virtualization" card (weight 1000)
const NETBOX_CARD_WEIGHT = 1100;
const NETBOX_SYNC_ACTION_WEIGHT = 100;

addGlobalFill(
  'host-tab-details-cards',
  'Netbox',
  <NetboxCard key="netbox-card" />,
  NETBOX_CARD_WEIGHT
);

addGlobalFill(
  'host-details-kebab',
  'netbox-sync',
  <NetboxSyncAction key="netbox-sync-action" />,
  NETBOX_SYNC_ACTION_WEIGHT
);
