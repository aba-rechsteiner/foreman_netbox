# frozen_string_literal: true

require 'test_plugin_helper'

class SyncHostObjectTypeTest < ActiveSupport::TestCase
  setup do
    setup_netbox_integration_test
    # leftovers of previous runs
    ForemanNetbox::Api.client.dcim.devices.filter(name: host.name).each(&:delete)
    ForemanNetbox::Api.client.virtualization.virtual_machines.filter(name: host.name).each(&:delete)
  end

  let(:ip) { '10.0.0.12' }
  let(:facts_json) { JSON.parse(file_fixture('facts/rhel_physical_host.json').read).merge('serialnumber' => 'OBJECTTYPE123') }
  let(:host) do
    FactoryBot.build_stubbed(
      :host,
      hostname: 'object_type_host.tier.example.com',
      owner: FactoryBot.build_stubbed(:usergroup, name: 'Owner'),
      location: FactoryBot.build_stubbed(:location, name: 'Location'),
      interfaces: [
        FactoryBot.build_stubbed(
          :nic_base,
          identifier: 'eth0',
          mac: 'C3:CD:63:54:21:72',
          ip: ip,
          subnet: FactoryBot.build_stubbed(:subnet_ipv4, organizations: [], locations: [])
        ),
      ]
    ).tap do |host|
      host.stubs(:ip).returns(ip)
      host.stubs(:ip6).returns(nil)
      host.stubs(:compute?).returns(true)
      host.stubs(:compute_resource).returns(OpenStruct.new(type: 'Foreman::Model::Libvirt', name: 'kvm01'))
      host.stubs(:compute_object).returns(
        OpenStruct.new(cpus: 2, memory_size: 2_097_152, volumes: [OpenStruct.new(name: 'object_type_host.qcow2', capacity: 20)])
      )
      host.stubs(:facts).returns(facts_json)
      host.stubs(:host_params).returns({})
    end
  end

  test 'a virtual machine with virtual disks becomes a device' do
    ForemanNetbox::NetboxFacet.any_instance.stubs(:update).returns(true)

    vm_result = ForemanNetbox::SyncHost::Organizer.call(host: host)
    assert vm_result.success?, vm_result.error
    virtual_machine_id = vm_result.virtual_machine.id
    virtual_disks = ForemanNetbox::Api.virtual_disks.filter(virtual_machine_id: virtual_machine_id)
    assert_equal [['object_type_host.qcow2', 20_000]], (virtual_disks.map { |virtual_disk| [virtual_disk.name, virtual_disk.size] })
    assert_equal 20_000, ForemanNetbox::Api.client.virtualization.virtual_machine(virtual_machine_id).disk
    assert_equal 'kvm01', vm_result.cluster.name

    host.netbox_facet.raw_data = vm_result.raw_data
    host.stubs(:host_params).returns('netbox_object_type' => 'device')

    device_result = ForemanNetbox::SyncHost::Organizer.call(host: host)
    assert device_result.success?, device_result.error
    assert_empty ForemanNetbox::Api.client.virtualization.virtual_machines.filter(id: virtual_machine_id).to_a
    assert_equal host.name, device_result.device.name
    assert_equal IPAddress.parse("#{ip}/24"), device_result.device.primary_ip4.address
  end
end
