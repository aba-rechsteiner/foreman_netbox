# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanNetbox
  class SyncHostsTest < ActiveSupport::TestCase
    let(:host) { FactoryBot.create(:host, :managed) }
    let(:successful_sync) { Interactor::Context.new }
    let(:failed_sync) { Interactor::Context.new(error: 'Netbox is not reachable').tap { |context| context.fail! rescue nil } }

    describe '.call' do
      it 'synchronizes the managed hosts matching the search' do
        Host::Managed.any_instance.expects(:push_to_netbox).once.returns(successful_sync)

        result = ForemanNetbox::SyncHosts.call(search: "name = #{host.name}")

        assert_equal [host.name], result.synchronized
        assert_empty result.failed
      end

      it 'synchronizes all managed hosts without a search' do
        Host::Managed.any_instance.expects(:push_to_netbox).times(Host::Managed.where(managed: true).count).returns(successful_sync)

        ForemanNetbox::SyncHosts.call
      end

      it 'does not synchronize unmanaged hosts' do
        unmanaged_host = FactoryBot.create(:host, managed: false)
        Host::Managed.any_instance.expects(:push_to_netbox).never

        assert_empty ForemanNetbox::SyncHosts.call(search: "name = #{unmanaged_host.name}").synchronized
      end

      it 'reports hosts that failed to synchronize' do
        Host::Managed.any_instance.stubs(:push_to_netbox).returns(failed_sync)

        result = ForemanNetbox::SyncHosts.call(search: "name = #{host.name}")

        assert_equal({ host.name => 'Netbox is not reachable' }, result.failed)
      end

      it 'continues after an exception' do
        Host::Managed.any_instance.stubs(:push_to_netbox).raises(StandardError, 'unexpected')

        assert_equal({ host.name => 'unexpected' }, ForemanNetbox::SyncHosts.call(search: "name = #{host.name}").failed)
      end

      context 'with only_changed' do
        subject { ForemanNetbox::SyncHosts.call(search: "name = #{host.name}", only_changed: true) }

        setup do
          Host::Managed.any_instance.stubs(:push_to_netbox).returns(successful_sync)
          ForemanNetbox::NetboxFacet.any_instance.stubs(:netbox_will_change?).returns(false)
        end

        it 'synchronizes hosts that were never synchronized' do
          assert_equal [host.name], subject.synchronized
        end

        it 'skips hosts without changes' do
          FactoryBot.create(:netbox_facet, host: host)

          assert_equal [host.name], subject.skipped
        end

        it 'synchronizes hosts that failed to synchronize' do
          FactoryBot.create(:netbox_facet, host: host, synchronization_error: 'error')

          assert_equal [host.name], subject.synchronized
        end

        it 'synchronizes hosts with changes' do
          FactoryBot.create(:netbox_facet, host: host)
          ForemanNetbox::NetboxFacet.any_instance.stubs(:netbox_will_change?).returns(true)

          assert_equal [host.name], subject.synchronized
        end
      end
    end

    describe '.periodic' do
      it 'does nothing if the periodic synchronization is disabled' do
        Setting[:netbox_periodic_sync] = 'disabled'
        ForemanNetbox::SyncHosts.expects(:call).never

        assert_nil ForemanNetbox::SyncHosts.periodic('daily')
      end

      it 'does nothing for another cadence' do
        Setting[:netbox_periodic_sync] = 'hourly'
        ForemanNetbox::SyncHosts.expects(:call).never

        assert_nil ForemanNetbox::SyncHosts.periodic('daily')
      end

      it 'synchronizes hosts with changes for the selected cadence' do
        Setting[:netbox_periodic_sync] = 'daily'
        ForemanNetbox::SyncHosts.expects(:call).with(only_changed: true)
                                .returns(ForemanNetbox::SyncHosts::Result.new(synchronized: [], failed: {}, skipped: []))

        ForemanNetbox::SyncHosts.periodic('daily')
      end
    end
  end
end
