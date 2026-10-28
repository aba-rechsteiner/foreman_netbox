# frozen_string_literal: true

require 'test_plugin_helper'

class SyncHostWithParametersTest < ActiveSupport::TestCase
  setup do
    setup_netbox_integration_test
    ensure_custom_field('owner_team')
  end

  subject { ForemanNetbox::SyncHost::Organizer.call(host: host) }

  let(:ip) { '10.0.0.11' }
  let(:facts_json) { JSON.parse(file_fixture('facts/rhel_physical_host.json').read).merge('serialnumber' => 'PARAMETERS123') }
  let(:host) do
    FactoryBot.build_stubbed(
      :host,
      hostname: 'parameters_host.tier.example.com',
      owner: FactoryBot.build_stubbed(:usergroup, name: 'Owner'),
      location: FactoryBot.build_stubbed(:location, name: 'Location'),
      interfaces: [
        FactoryBot.build_stubbed(
          :nic_base,
          identifier: 'eth0',
          mac: 'C3:CD:63:54:21:70',
          ip: ip,
          subnet: FactoryBot.build_stubbed(:subnet_ipv4, organizations: [], locations: [])
        ),
      ]
    ).tap do |host|
      host.stubs(:ip).returns(ip)
      host.stubs(:ip6).returns(nil)
      host.stubs(:compute?).returns(false)
      host.stubs(:facts).returns(facts_json)
      host.stubs(:host_params).returns(
        'netbox_device_role' => 'Hypervisor',
        'netbox_status' => 'planned',
        'netbox_tenant' => 'Parameter Tenant',
        'netbox_cf_owner_team' => 'ops'
      )
    end
  end

  test 'sync host with Foreman parameters and a reserved IP address' do
    ForemanNetbox::NetboxFacet.any_instance.expects(:update).twice.returns(true)
    reserved_ip_address = reserve_ip_address("#{ip}/32")

    assert subject.success?, subject.error

    device = ForemanNetbox::Api.client.dcim.device(subject.device.id)
    assert_equal 'hypervisor', device['role']['slug']
    assert_equal 'planned', device['status']['value']
    assert_equal 'Parameter Tenant', device.tenant.name
    assert_equal 'ops', device['custom_fields']['owner_team']

    ip_address = ForemanNetbox::Api.client.ipam.ip_address(reserved_ip_address.id)
    assert_equal IPAddress.parse("#{ip}/24"), ip_address.address
    assert_equal 'dcim.interface', ip_address['assigned_object_type']
    assert_equal subject.interfaces.find { |i| i.name == 'eth0' }.id, ip_address['assigned_object_id']
    assert_equal reserved_ip_address.id, device.primary_ip4.id
  end

  private

  def ensure_custom_field(name)
    ForemanNetbox::Api.client # configures the connection
    connection = NetboxClientRuby::Connection.new
    return if connection.get('extras/custom-fields/', name: name).body['count'].positive?

    connection.post('extras/custom-fields/', name: name, type: 'text', object_types: ['dcim.device', 'virtualization.virtualmachine'])
  end

  # an IP address which is reserved in Netbox, but not assigned
  def reserve_ip_address(address)
    ForemanNetbox::Api.client.ipam.ip_addresses.filter(address: address.split('/').first).each(&:delete)
    ForemanNetbox::Api.client::IPAM::IpAddress.new(address: address).save
  end
end
