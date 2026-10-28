import React from 'react';
import { addGlobalFill } from 'foremanReact/components/common/Fill/GlobalFill';
import NetboxCard from './src/Components/NetboxCard';

// show the card after the core "Virtualization" card (weight 1000)
const NETBOX_CARD_WEIGHT = 1100;

addGlobalFill(
  'host-tab-details-cards',
  'Netbox',
  <NetboxCard key="netbox-card" />,
  NETBOX_CARD_WEIGHT
);
