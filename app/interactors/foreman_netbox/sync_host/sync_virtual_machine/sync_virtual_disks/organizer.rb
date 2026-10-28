# frozen_string_literal: true

module ForemanNetbox
  module SyncHost
    module SyncVirtualMachine
      module SyncVirtualDisks
        class Organizer
          include ::Interactor::Organizer

          # only if the virtual disks of the host are known from its compute resource
          around do |interactor|
            interactor.call if context.netbox_params.key?(:virtual_disks)
          end

          after do
            context.raw_data[:virtual_disks] = context.virtual_disks.reload.raw_data!
          end

          organize SyncVirtualDisks::Find,
            SyncVirtualDisks::Delete,
            SyncVirtualDisks::Update,
            SyncVirtualDisks::Create
        end
      end
    end
  end
end
