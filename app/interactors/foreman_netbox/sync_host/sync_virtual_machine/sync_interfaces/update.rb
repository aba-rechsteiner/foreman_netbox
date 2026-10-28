# frozen_string_literal: true

module ForemanNetbox
  module SyncHost
    module SyncVirtualMachine
      module SyncInterfaces
        class Update
          include ::Interactor
          include ForemanNetbox::Concerns::AssignTags

          def call
            context.interfaces.each { |netbox_interface| update(netbox_interface) }
          end

          private

          delegate :netbox_params, to: :context

          def update(netbox_interface)
            new_params = netbox_params.fetch(:interfaces, [])
                                      .find { |i| i[:name] == netbox_interface.name }

            return unless new_params

            old_mac_address = netbox_interface.mac_address
            netbox_interface.mac_address = new_params[:mac_address] if old_mac_address != new_params[:mac_address]
            assign_tags_to(netbox_interface)

            netbox_interface.save
            delete_mac_address(netbox_interface, old_mac_address) if old_mac_address && old_mac_address != new_params[:mac_address]
          rescue NetboxClientRuby::LocalError, NetboxClientRuby::ClientError, NetboxClientRuby::RemoteError => e
            ::Foreman::Logging.logger('foreman_netbox/import').error("#{self.class} error #{e}: #{e.backtrace}")
            context.fail!(error: "#{self.class}: #{e}")
          end

          # Netbox keeps a replaced MAC address assigned to the interface as a non-primary MAC address
          def delete_mac_address(netbox_interface, mac_address)
            ForemanNetbox::Api.client.dcim.mac_addresses
                              .filter(vminterface_id: netbox_interface.id, mac_address: mac_address)
                              .each(&:delete)
          end
        end
      end
    end
  end
end
