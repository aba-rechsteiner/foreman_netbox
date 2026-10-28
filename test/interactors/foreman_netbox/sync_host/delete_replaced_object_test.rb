# frozen_string_literal: true

require 'test_plugin_helper'

class DeleteReplacedObjectTest < ActiveSupport::TestCase
  subject { ForemanNetbox::SyncHost::DeleteReplacedObject.call(host: host) }

  let(:virtual_machine) { true }
  let(:raw_data) { {} }
  let(:host) do
    FactoryBot.build_stubbed(:host).tap do |host|
      host.stubs(:netbox_virtual_machine?).returns(virtual_machine)
      host.netbox_facet.raw_data = raw_data
    end
  end

  setup do
    setup_default_netbox_settings
  end

  context 'when a device is now a virtual machine' do
    let(:raw_data) { { 'device' => { 'id' => 7, 'name' => 'old.example.com' } } }

    it 'deletes the device of the last synchronization' do
      stub_get = stub_request(:get, "#{Setting[:netbox_url]}/api/dcim/devices/").with(query: { limit: 50, id: 7 }).to_return(
        status: 200, headers: { 'Content-Type': 'application/json' },
        body: { count: 1, results: [{ id: 7, name: 'old.example.com' }] }.to_json
      )
      stub_delete = stub_request(:delete, "#{Setting[:netbox_url]}/api/dcim/devices/7/").to_return(status: 204)

      assert subject.success?
      assert_requested(stub_get)
      assert_requested(stub_delete)
    end
  end

  context 'when a virtual machine is now a device' do
    let(:virtual_machine) { false }
    let(:raw_data) { { virtual_machine: { id: 8, name: 'old.example.com' } } }

    it 'deletes the virtual machine of the last synchronization' do
      stub_request(:get, "#{Setting[:netbox_url]}/api/virtualization/virtual-machines/").with(query: { limit: 50, id: 8 }).to_return(
        status: 200, headers: { 'Content-Type': 'application/json' },
        body: { count: 1, results: [{ id: 8, name: 'old.example.com' }] }.to_json
      )
      stub_delete = stub_request(:delete, "#{Setting[:netbox_url]}/api/virtualization/virtual-machines/8/").to_return(status: 204)

      assert subject.success?
      assert_requested(stub_delete)
    end
  end

  context 'when the type did not change' do
    let(:raw_data) { { 'virtual_machine' => { 'id' => 8 } } }

    it 'does not delete anything' do
      assert subject.success?
      assert_not_requested(:any, /#{Setting[:netbox_url]}/)
    end
  end
end
