# frozen_string_literal: true

require 'test_plugin_helper'

class SyncVirtualDisksTest < ActiveSupport::TestCase
  subject do
    ForemanNetbox::SyncHost::SyncVirtualMachine::SyncVirtualDisks::Organizer.call(
      virtual_machine: OpenStruct.new(id: 1),
      netbox_params: netbox_params,
      tags: default_tags,
      raw_data: {}
    )
  end

  let(:netbox_params) do
    { virtual_disks: [{ name: 'Hard disk 1', size: 20_000 }, { name: 'Hard disk 2', size: 30_000 }] }
  end
  let(:tags) { default_tags.map { |tag| { id: tag.id, name: tag.name, slug: tag.slug } } }
  let(:existing_virtual_disks) do
    [
      { id: 11, name: 'Hard disk 1', size: 10_000, tags: tags },
      { id: 12, name: 'Old disk', size: 5_000, tags: tags },
    ]
  end

  setup do
    setup_default_netbox_settings
    stub_request(:get, "#{Setting[:netbox_url]}/api/virtualization/virtual-disks/").with(query: { limit: 50, virtual_machine_id: 1 }).to_return(
      status: 200, headers: { 'Content-Type': 'application/json' },
      body: { count: existing_virtual_disks.size, results: existing_virtual_disks }.to_json
    )
  end

  it 'synchronizes the virtual disks of the virtual machine' do
    stub_delete = stub_request(:delete, "#{Setting[:netbox_url]}/api/virtualization/virtual-disks/12/").to_return(status: 204)
    stub_update = stub_request(:patch, "#{Setting[:netbox_url]}/api/virtualization/virtual-disks/11/").with(
      body: { size: 20_000 }.to_json
    ).to_return(status: 200, headers: { 'Content-Type': 'application/json' }, body: { id: 11 }.to_json)
    stub_create = stub_request(:post, "#{Setting[:netbox_url]}/api/virtualization/virtual-disks/").with(
      body: { name: 'Hard disk 2', size: 30_000, virtual_machine: 1, tags: default_tags.map(&:id) }.to_json
    ).to_return(status: 201, headers: { 'Content-Type': 'application/json' }, body: { id: 13 }.to_json)

    assert subject.success?
    assert_requested(stub_delete)
    assert_requested(stub_update)
    assert_requested(stub_create)
    assert subject.raw_data.key?(:virtual_disks)
  end

  context 'without virtual disks from the compute resource' do
    let(:netbox_params) { {} }

    it 'does not change the virtual disks in Netbox' do
      assert subject.success?
      assert_not_requested(:any, /#{Setting[:netbox_url]}/)
    end
  end
end
