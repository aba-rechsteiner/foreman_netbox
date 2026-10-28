# frozen_string_literal: true

require 'test_plugin_helper'

class NetboxHostsControllerTest < ActionController::TestCase
  tests ::HostsController

  let(:host) { FactoryBot.create(:host) }

  test 'shows the Netbox tab on the legacy host page' do
    facet = FactoryBot.create(:netbox_facet, host: host)

    get :show, params: { id: host.to_param }, session: set_session_user
    assert_response :success
    assert_select '#netbox_table a[href=?]', facet.url
  end

  test 'does not show the Netbox tab for a host that was never synchronized' do
    get :show, params: { id: host.to_param }, session: set_session_user
    assert_response :success
    assert_select '#netbox_table', false
  end
end
