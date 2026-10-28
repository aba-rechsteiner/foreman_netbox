# frozen_string_literal: true

module ForemanNetbox
  module SyncHost
    # Deletes the Netbox object a host was synchronized to before, if it changed from device to virtual machine
    # or vice versa (Foreman parameter netbox_object_type). Only the object from the last synchronization is deleted.
    class DeleteReplacedObject
      include ::Interactor

      def call
        if host.netbox_virtual_machine?
          delete(ForemanNetbox::Api.client.dcim.devices, :device)
        else
          delete(ForemanNetbox::Api.client.virtualization.virtual_machines, :virtual_machine)
        end
      rescue NetboxClientRuby::LocalError, NetboxClientRuby::ClientError, NetboxClientRuby::RemoteError => e
        ::Foreman::Logging.logger('foreman_netbox/import').error("#{self.class} error #{e}: #{e.backtrace}")
        context.fail!(error: "#{self.class}: #{e}")
      end

      private

      delegate :host, to: :context

      def delete(collection, raw_data_key)
        id = host.netbox_facet.raw_data&.with_indifferent_access&.dig(raw_data_key, :id)
        return unless id

        collection.filter(id: id).each(&:delete)
      end
    end
  end
end
