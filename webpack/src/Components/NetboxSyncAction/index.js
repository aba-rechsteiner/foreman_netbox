import React, { useContext } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { DropdownItem, Icon } from '@patternfly/react-core';
import { SyncAltIcon } from '@patternfly/react-icons';
import { translate as __ } from 'foremanReact/common/I18n';
import { foremanUrl } from 'foremanReact/common/helpers';
import { get, put } from 'foremanReact/redux/API';
import { selectAPIResponse } from 'foremanReact/redux/API/APISelectors';
import { addToast } from 'foremanReact/components/ToastsList/slice';
import { HOST_DETAILS_KEY } from 'foremanReact/components/HostDetails/consts';
import { ForemanActionsBarContext } from 'foremanReact/components/HostDetails/ActionsBar';

export const NETBOX_SYNC_KEY = 'NETBOX_SYNC';

const NetboxSyncAction = () => {
  const dispatch = useDispatch();
  const hostDetails = useSelector(state =>
    selectAPIResponse(state, HOST_DETAILS_KEY)
  );
  const { onKebabToggle } = useContext(ForemanActionsBarContext);
  const { permissions: { netbox_sync_hosts: canSync } = {} } =
    hostDetails || {};

  if (!canSync) return null;

  // reloads the host details, so the Netbox card shows the new synchronization status
  const refreshHostDetails = () =>
    dispatch(
      get({
        key: HOST_DETAILS_KEY,
        url: foremanUrl(
          `/api/hosts/${hostDetails.id}?show_hidden_parameters=true`
        ),
      })
    );

  const onClick = () => {
    onKebabToggle(false);
    dispatch(
      addToast({
        type: 'info',
        key: NETBOX_SYNC_KEY,
        message: __('Synchronizing the host with Netbox'),
      })
    );
    dispatch(
      put({
        key: NETBOX_SYNC_KEY,
        url: foremanUrl(`/api/hosts/${hostDetails.id}/netbox_sync`),
        successToast: () => __('The host was synchronized with Netbox'),
        errorToast: error =>
          error.response?.data?.error?.message ||
          __('The host could not be synchronized with Netbox'),
        handleSuccess: refreshHostDetails,
        handleError: refreshHostDetails,
      })
    );
  };

  return (
    <DropdownItem
      ouiaId="netbox-sync-dropdown-item"
      key="netbox-sync"
      onClick={onClick}
      component="button"
      icon={
        <Icon>
          <SyncAltIcon />
        </Icon>
      }
    >
      {__('Synchronize with Netbox')}
    </DropdownItem>
  );
};

export default NetboxSyncAction;
