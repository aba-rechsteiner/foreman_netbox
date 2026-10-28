# frozen_string_literal: true

module ForemanNetbox
  # Collection of ForemanNetbox::VirtualDisk, see there
  class VirtualDisks
    include NetboxClientRuby::Entities

    path 'virtualization/virtual-disks/'
    data_key 'results'
    count_key 'count'
    entity_creator :entity_creator

    private

    def entity_creator(raw_entity)
      ForemanNetbox::VirtualDisk.new raw_entity['id']
    end
  end
end
