# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanNetbox
  class HostExtensionsTest < ActiveSupport::TestCase
    let(:hostgroup) { FactoryBot.create(:hostgroup) }
    let(:host) { FactoryBot.create(:host, :managed, hostgroup: hostgroup) }

    setup do
      FactoryBot.create(:common_parameter, name: 'netbox_status', value: 'planned')
      FactoryBot.create(:common_parameter, name: 'netbox_tenant', value: 'Global Tenant')
      FactoryBot.create(:hostgroup_parameter, hostgroup: hostgroup, name: 'netbox_status', value: 'staged')
      FactoryBot.create(:hostgroup_parameter, hostgroup: hostgroup, name: 'netbox_device_role', value: 'Hypervisor')
      FactoryBot.create(:host_parameter, host: host, name: 'netbox_device_role', value: 'Database')
      FactoryBot.create(:host_parameter, host: host, name: 'netbox_cf_owner_team', value: 'ops')
      FactoryBot.create(:host_parameter, host: host, name: 'netbox_site', value: '')
    end

    describe '#netbox_host_param' do
      it 'uses the most specific parameter' do
        assert_equal 'Global Tenant', host.netbox_host_param(:tenant)
        assert_equal 'staged', host.netbox_host_param(:status)
        assert_equal 'Database', host.netbox_host_param(:device_role)
      end

      it 'ignores missing and empty parameters' do
        assert_nil host.netbox_host_param(:cluster)
        assert_nil host.netbox_host_param(:site)
      end

      it 'does not depend on the current user, as the synchronization runs in the background' do
        User.current = nil

        assert_equal 'Database', Host::Managed.find(host.id).netbox_host_param(:device_role)
      end
    end

    describe '#netbox_custom_fields' do
      it { assert_equal({ 'owner_team' => 'ops' }, host.netbox_custom_fields) }

      it 'renders ERB in parameter values' do
        FactoryBot.create(:host_parameter, host: host, name: 'netbox_cf_foreman_name', value: '<%= @host.name %>')

        assert_equal host.name, Host::Managed.find(host.id).netbox_custom_fields['foreman_name']
      end
    end
  end
end
