import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { CardExpansionContext } from 'foremanReact/components/HostDetails/CardExpansionContext';
import NetboxCard from './index';

jest.mock('foremanReact/components/common/dates/RelativeDateTime', () => ({
  date,
}) => <span>{date}</span>);

const renderCard = hostDetails =>
  render(
    <CardExpansionContext.Provider
      value={{
        cardExpandStates: { Netbox: true },
        dispatch: jest.fn(),
        registerCard: jest.fn(),
      }}
    >
      <NetboxCard hostDetails={hostDetails} />
    </CardExpansionContext.Provider>
  );

const synchronizedAt = '2026-10-28T08:00:00.000Z';
const url = 'https://netbox.example.com/dcim/devices/1';

describe('NetboxCard', () => {
  it('does not render for a host that was never synchronized', () => {
    const { container } = renderCard({
      netbox_facet_attributes: { synchronized_at: null },
    });

    expect(container.firstChild).toBeNull();
  });

  it('does not render without netbox facet attributes', () => {
    const { container } = renderCard({});

    expect(container.firstChild).toBeNull();
  });

  it('renders a successful synchronization', () => {
    renderCard({
      netbox_facet_attributes: { synchronized_at: synchronizedAt, url },
    });

    expect(screen.getByText('Netbox')).toBeInTheDocument();
    expect(screen.getByText(synchronizedAt)).toBeInTheDocument();
    expect(screen.getByText('OK')).toBeInTheDocument();
    expect(screen.getByRole('link', { name: url })).toHaveAttribute(
      'href',
      url
    );
  });

  it('renders a failed synchronization', () => {
    renderCard({
      netbox_facet_attributes: {
        synchronized_at: synchronizedAt,
        synchronization_error: 'Invalid Device parameters',
        url: null,
      },
    });

    expect(screen.getByText('Invalid Device parameters')).toBeInTheDocument();
    expect(screen.queryByText('OK')).not.toBeInTheDocument();
    expect(
      screen.getByText('No Netbox object is associated with this host')
    ).toBeInTheDocument();
  });
});
