# frozen_string_literal: true

require 'test_plugin_helper'

module Api
  module V2
    class NetboxHostsControllerTest < ActionController::TestCase
      tests ::Api::V2::HostsController

      let(:host) { FactoryBot.create(:host) }

      test 'should show netbox facet attributes' do
        facet = FactoryBot.create(:netbox_facet, host: host, synchronization_error: 'Some error')

        get :show, params: { id: host.to_param }
        assert_response :success

        netbox_facet_attributes = ActiveSupport::JSON.decode(@response.body)['netbox_facet_attributes']
        assert_equal facet.url, netbox_facet_attributes['url']
        assert_equal facet.synchronization_error, netbox_facet_attributes['synchronization_error']
        assert_not_nil netbox_facet_attributes['synchronized_at']
      end

      describe '#netbox_sync' do
        let(:sync_result) { Interactor::Context.new }
        let(:scoped_host) do
          FactoryBot.create(:host, owner: users(:scoped), organization: taxonomies(:organization1), location: taxonomies(:location1))
        end
        let(:scoped_search) { "owner_type = User and owner_id = #{users(:scoped).id}" }

        setup do
          Host::Managed.any_instance.stubs(:push_to_netbox).returns(sync_result)
          scoped_host # created before a restricted user is set up
        end

        test 'should synchronize the host with netbox' do
          facet = FactoryBot.create(:netbox_facet, host: host)

          put :netbox_sync, params: { id: host.to_param }
          assert_response :success
          assert_equal facet.url, ActiveSupport::JSON.decode(@response.body).dig('netbox_facet_attributes', 'url')
        end

        context 'when the synchronization fails' do
          let(:sync_result) do
            Interactor::Context.new(error: 'Netbox is not reachable').tap { |context| context.fail! rescue nil }
          end

          test 'should return the error' do
            put :netbox_sync, params: { id: host.to_param }
            assert_response :unprocessable_entity
            assert_equal 'Netbox is not reachable', ActiveSupport::JSON.decode(@response.body).dig('error', 'message')
          end
        end

        test 'should synchronize for a user with the permission netbox_sync_hosts' do
          as_admin { Permission.find_or_create_by!(name: 'netbox_sync_hosts', resource_type: 'Host') }
          setup_user 'netbox_sync', 'hosts', scoped_search, :scoped

          put :netbox_sync, params: { id: scoped_host.to_param }
          assert_response :success
        end

        test 'should not synchronize for a user without the permission netbox_sync_hosts' do
          setup_user 'view', 'hosts', scoped_search, :scoped

          put :netbox_sync, params: { id: scoped_host.to_param }
          assert_response :forbidden
        end
      end

      test 'should show empty netbox facet attributes for a host that was never synchronized' do
        get :show, params: { id: host.to_param }
        assert_response :success

        netbox_facet_attributes = ActiveSupport::JSON.decode(@response.body)['netbox_facet_attributes']
        assert_nil netbox_facet_attributes['synchronized_at']
        assert_nil netbox_facet_attributes['url']
      end
    end
  end
end
