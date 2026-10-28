# frozen_string_literal: true

module ForemanNetbox
  module HostExtensions
    extend ActiveSupport::Concern

    included do
      include ::Orchestration::Netbox
    end

    def netbox_facet
      @netbox_facet ||= super || ForemanNetbox::NetboxFacet.new(host: self)
    end

    def push_to_netbox_async
      ForemanNetbox::SyncHostJob.perform_later(id)
    end

    def push_to_netbox
      ForemanNetbox::SyncHost::Organizer.call(host: self)
    end

    def delete_from_netbox
      ForemanNetbox::DeleteHost::Organizer.call(host: self)
    end

    # Value of the Foreman parameter "netbox_<name>", which can be set on every level (global, organization,
    # location, host group, host, ...) to override what is sent to Netbox
    def netbox_host_param(name)
      netbox_host_params["netbox_#{name}"].presence
    end

    # Netbox custom fields from the Foreman parameters "netbox_cf_<custom field name>"
    def netbox_custom_fields
      netbox_host_params.each_with_object({}) do |(name, value), custom_fields|
        custom_fields[name.delete_prefix('netbox_cf_')] = value if name.start_with?('netbox_cf_')
      end
    end

    private

    # Parameters are filtered by the permissions of the current user, but the synchronization runs as a
    # background job, so the parameters have to be read independent of the current user
    def netbox_host_params
      User.as_anonymous_admin { host_params }
    end
  end
end
