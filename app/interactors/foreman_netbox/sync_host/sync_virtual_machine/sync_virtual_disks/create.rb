# frozen_string_literal: true

module ForemanNetbox
  module SyncHost
    module SyncVirtualMachine
      module SyncVirtualDisks
        class Create
          include ::Interactor
          include ForemanNetbox::Concerns::AssignTags

          def call
            existing_names = context.virtual_disks.map(&:name)

            netbox_params.fetch(:virtual_disks, [])
                         .reject { |params| existing_names.include?(params[:name]) }
                         .each do |params|
                           ForemanNetbox::VirtualDisk.new(
                             params.merge(virtual_machine: virtual_machine.id, tags: default_tag_ids)
                           ).save
                         end
          rescue NetboxClientRuby::LocalError, NetboxClientRuby::ClientError, NetboxClientRuby::RemoteError => e
            ::Foreman::Logging.logger('foreman_netbox/import').error("#{self.class} error #{e}: #{e.backtrace}")
            context.fail!(error: "#{self.class}: #{e}")
          end

          delegate :netbox_params, :virtual_machine, to: :context
        end
      end
    end
  end
end
