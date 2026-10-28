# frozen_string_literal: true

module ForemanNetbox
  # Virtual disks of virtual machines (Netbox >= 3.7), which netbox-client-ruby does not support.
  # Use ForemanNetbox::Api.virtual_disks, which configures the connection.
  class VirtualDisk
    include NetboxClientRuby::Entity

    id id: :id
    deletable true
    path 'virtualization/virtual-disks/:id/'
    creation_path 'virtualization/virtual-disks/'
  end
end
