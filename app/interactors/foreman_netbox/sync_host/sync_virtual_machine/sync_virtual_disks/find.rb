# frozen_string_literal: true

module ForemanNetbox
  module SyncHost
    module SyncVirtualMachine
      module SyncVirtualDisks
        class Find
          include ::Interactor

          def call
            context.virtual_disks = ForemanNetbox::Api.virtual_disks.filter(virtual_machine_id: virtual_machine.id)
          rescue NetboxClientRuby::LocalError, NetboxClientRuby::ClientError, NetboxClientRuby::RemoteError => e
            ::Foreman::Logging.logger('foreman_netbox/import').error("#{self.class} error #{e}: #{e.backtrace}")
            context.fail!(error: "#{self.class}: #{e}")
          end

          delegate :virtual_machine, to: :context
        end
      end
    end
  end
end
