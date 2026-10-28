import React from 'react';
import { screen, fireEvent, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import { rtlHelpers } from 'foremanReact/common/rtlTestHelpers';
import API from 'foremanReact/redux/API/API';
import { HOST_DETAILS_KEY } from 'foremanReact/components/HostDetails/consts';
import { ForemanActionsBarContext } from 'foremanReact/components/HostDetails/ActionsBar';
import NetboxSyncAction from './index';

jest.mock('foremanReact/redux/API/API');

const renderAction = (permissions, onKebabToggle = jest.fn()) =>
  rtlHelpers.renderWithStore(
    <ForemanActionsBarContext.Provider value={{ onKebabToggle }}>
      <NetboxSyncAction />
    </ForemanActionsBarContext.Provider>,
    {
      API: {
        [HOST_DETAILS_KEY]: {
          response: { id: 1, name: 'host.example.com', permissions },
          status: 'RESOLVED',
        },
      },
    }
  );

describe('NetboxSyncAction', () => {
  beforeEach(() => {
    API.put.mockResolvedValue({ data: {} });
    API.get.mockResolvedValue({ data: {} });
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('is hidden without the permission netbox_sync_hosts', () => {
    renderAction({ netbox_sync_hosts: false });

    expect(
      screen.queryByText('Synchronize with Netbox')
    ).not.toBeInTheDocument();
  });

  it('synchronizes the host and reloads the host details', async () => {
    const onKebabToggle = jest.fn();
    renderAction({ netbox_sync_hosts: true }, onKebabToggle);

    fireEvent.click(screen.getByText('Synchronize with Netbox'));

    expect(onKebabToggle).toHaveBeenCalledWith(false);
    await waitFor(() => expect(API.put).toHaveBeenCalled());
    expect(API.put.mock.calls[0][0]).toContain('/api/hosts/1/netbox_sync');
    await waitFor(() => expect(API.get).toHaveBeenCalled());
    expect(API.get.mock.calls[0][0]).toContain('/api/hosts/1');
  });
});
