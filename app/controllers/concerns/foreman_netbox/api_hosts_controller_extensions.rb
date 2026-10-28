# frozen_string_literal: true

module ForemanNetbox
  # Prepended to Api::V2::HostsController, so action_permission can extend the one of the controller
  module ApiHostsControllerExtensions
    extend ActiveSupport::Concern

    prepended do
      api :PUT, '/hosts/:id/netbox_sync', N_('Synchronize a host with Netbox')
      param :id, :identifier_dottable, required: true

      def netbox_sync
        result = @host.push_to_netbox
        netbox_facet = @host.netbox_facet

        if result.success?
          render json: { netbox_facet_attributes: netbox_facet.slice(:url, :synchronized_at, :synchronization_error) }
        else
          render_error :custom_error, status: :unprocessable_entity, locals: { message: result.error }
        end
      end
    end

    private

    # the host is found by the permission netbox_sync_hosts
    def action_permission
      params[:action] == 'netbox_sync' ? :netbox_sync : super
    end
  end
end
