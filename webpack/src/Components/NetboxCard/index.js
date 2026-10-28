import React from 'react';
import PropTypes from 'prop-types';
import {
  DescriptionList,
  DescriptionListGroup,
  DescriptionListTerm,
  DescriptionListDescription,
  Label,
} from '@patternfly/react-core';
import {
  CheckCircleIcon,
  ExclamationCircleIcon,
} from '@patternfly/react-icons';
import { translate as __ } from 'foremanReact/common/I18n';
import CardTemplate from 'foremanReact/components/HostDetails/Templates/CardItem/CardTemplate';
import RelativeDateTime from 'foremanReact/components/common/dates/RelativeDateTime';

const NetboxCard = ({ hostDetails }) => {
  const {
    synchronized_at: synchronizedAt,
    synchronization_error: synchronizationError,
    url,
  } = hostDetails.netbox_facet_attributes || {};

  // like the legacy tab, the card is only shown for hosts that have been synchronized
  if (!synchronizedAt) return null;

  return (
    <CardTemplate header={__('Netbox')} expandable masonryLayout>
      <DescriptionList isCompact isHorizontal>
        <DescriptionListGroup>
          <DescriptionListTerm>
            {__('Last Synchronization')}
          </DescriptionListTerm>
          <DescriptionListDescription>
            <RelativeDateTime date={synchronizedAt} />
          </DescriptionListDescription>
        </DescriptionListGroup>
        <DescriptionListGroup>
          <DescriptionListTerm>{__('Status')}</DescriptionListTerm>
          <DescriptionListDescription>
            {synchronizationError ? (
              <Label color="red" icon={<ExclamationCircleIcon />}>
                {synchronizationError}
              </Label>
            ) : (
              <Label color="green" icon={<CheckCircleIcon />}>
                {__('OK')}
              </Label>
            )}
          </DescriptionListDescription>
        </DescriptionListGroup>
        <DescriptionListGroup>
          <DescriptionListTerm>{__('Link')}</DescriptionListTerm>
          <DescriptionListDescription>
            {url ? (
              <a href={url} target="_blank" rel="noopener noreferrer">
                {url}
              </a>
            ) : (
              __('No Netbox object is associated with this host')
            )}
          </DescriptionListDescription>
        </DescriptionListGroup>
      </DescriptionList>
    </CardTemplate>
  );
};

NetboxCard.propTypes = {
  hostDetails: PropTypes.shape({
    netbox_facet_attributes: PropTypes.shape({
      synchronized_at: PropTypes.string,
      synchronization_error: PropTypes.string,
      url: PropTypes.string,
    }),
  }),
};

NetboxCard.defaultProps = {
  hostDetails: {},
};

export default NetboxCard;
