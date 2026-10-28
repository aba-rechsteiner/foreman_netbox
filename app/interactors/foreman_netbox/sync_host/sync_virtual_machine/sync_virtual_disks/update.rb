# frozen_string_literal: true

module ForemanNetbox
  module SyncHost
    module SyncVirtualMachine
      module SyncVirtualDisks
        class Update
          include ::Interactor
          include ForemanNetbox::Concerns::AssignTags

          def call
            context.virtual_disks.each { |virtual_disk| update(virtual_disk) }
          end

          private

          delegate :netbox_params, to: :context

          def update(virtual_disk)
            new_params = netbox_params.fetch(:virtual_disks, []).find { |params| params[:name] == virtual_disk.name }
            return unless new_params

            virtual_disk.size = new_params[:size] if virtual_disk.size != new_params[:size]
            assign_tags_to(virtual_disk)

            virtual_disk.save
          rescue NetboxClientRuby::LocalError, NetboxClientRuby::ClientError, NetboxClientRuby::RemoteError => e
            ::Foreman::Logging.logger('foreman_netbox/import').error("#{self.class} error #{e}: #{e.backtrace}")
            context.fail!(error: "#{self.class}: #{e}")
          end
        end
      end
    end
  end
end
