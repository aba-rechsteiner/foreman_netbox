# frozen_string_literal: true

module ForemanNetbox
  module SyncHost
    module SyncVirtualMachine
      module SyncVirtualDisks
        class Delete
          include ::Interactor

          def call
            context.virtual_disks
                   .reject { |virtual_disk| virtual_disk_names.include?(virtual_disk.name) }
                   .each(&:delete)
          rescue NetboxClientRuby::LocalError, NetboxClientRuby::ClientError, NetboxClientRuby::RemoteError => e
            ::Foreman::Logging.logger('foreman_netbox/import').error("#{self.class} error #{e}: #{e.backtrace}")
            context.fail!(error: "#{self.class}: #{e}")
          end

          private

          delegate :netbox_params, to: :context

          def virtual_disk_names
            netbox_params.fetch(:virtual_disks, []).map { |virtual_disk| virtual_disk[:name] }
          end
        end
      end
    end
  end
end
