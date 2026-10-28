# frozen_string_literal: true

module ForemanNetbox
  module SyncHost
    module SyncVirtualMachine
      module SyncInterfaces
        module SyncIpAddresses
          class Create
            include ::Interactor
            include ForemanNetbox::Concerns::AssignTags
            include ForemanNetbox::Concerns::UnassignedIpAddresses

            def call
              netbox_params.fetch(:ip_addresses, []).map do |ip_address|
                interface_id = interfaces_map.fetch(ip_address.dig(:interface, :name), nil)

                next unless interface_id
                next unless ForemanNetbox::Api.client
                                              .ipam
                                              .ip_addresses
                                              .filter(vminterface_id: interface_id, address: ip_address[:address])
                                              .total
                                              .zero?

                assign_or_create(ip_address, interface_id)
              end
            rescue NetboxClientRuby::LocalError, NetboxClientRuby::ClientError, NetboxClientRuby::RemoteError => e
              ::Foreman::Logging.logger('foreman_netbox/import').error("#{self.class} error #{e}: #{e.backtrace}")
              context.fail!(error: "#{self.class}: #{e}")
            end

            private

            delegate :interfaces, :netbox_params, to: :context

            def assign_or_create(ip_address, interface_id)
              params = ip_address.slice(:address).merge(assigned_object_type: 'virtualization.vminterface', assigned_object_id: interface_id)
              unassigned_ip_address = find_unassigned_ip_address(ip_address[:address])

              if unassigned_ip_address
                assign_tags_to(unassigned_ip_address)
                unassigned_ip_address.update(params)
              else
                ForemanNetbox::Api.client::IPAM::IpAddress.new(params.merge(tags: default_tag_ids)).save
              end
            end

            def interfaces_map
              interfaces.each_with_object({}) do |int, memo|
                memo[int.name] = int.id
              end
            end
          end
        end
      end
    end
  end
end
