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
