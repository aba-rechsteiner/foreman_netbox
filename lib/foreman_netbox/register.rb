# frozen_string_literal: true

Foreman::Plugin.register :foreman_netbox do
  requires_foreman '>= 5.0'

  # Netbox Facet
  register_facet(ForemanNetbox::NetboxFacet, :netbox_facet) do
    api_view single: 'foreman_netbox/api/v2/hosts/netbox_facet'
    set_dependent_action :destroy
  end

  # extend legacy host show page
  extend_page('hosts/show') do |context|
    context.add_pagelet :main_tabs,
      name: N_('Netbox'),
      partial: 'hosts/netbox_tab',
      onlyif: proc { |host| host.netbox_facet.synchronized_at }
  end

  # extend new host details page
  register_global_js_file 'global'

  settings do
    category(:netbox, N_('Netbox')) do
      setting 'netbox_url',
        type: :string,
        default: '-',
        full_name: N_('Netbox UI URL'),
        description: N_('URL where Netbox UI is reachable')
      setting 'netbox_api_url',
        type: :string,
        default: '-',
        full_name: N_('Netbox API URL'),
        description: N_('URL where Netbox API is reachable, in case it is different than Netbox UI')
      setting 'netbox_api_token',
        type: :string,
        default: '-',
        full_name: N_('Netbox API token'),
        description: N_('API token to Netbox, either a v2 token in the form nbt_<key>.<token> or a legacy v1 token')
      setting 'netbox_orchestration_enabled',
        type: :boolean,
        default: false,
        full_name: N_('Netbox Orchestration'),
        description: N_('Enable Netbox Orchestration')
      setting 'netbox_skip_site_update',
        type: :boolean,
        default: false,
        full_name: N_('Skip Site Update'),
        description: N_('Skip updating Site attribute for Devices')
      setting 'netbox_disk_base_unit',
        type: :integer,
        default: 1000,
        full_name: N_('Netbox disk base unit'),
        description: N_('Megabytes per gigabyte used to send the disk size of virtual machines to Netbox, should match DISK_BASE_UNIT of Netbox'),
        collection: proc { { 1000 => _('1000 (GB)'), 1024 => _('1024 (GiB)') } }
      validates('netbox_disk_base_unit', ->(value) { [1000, 1024].include?(value) }, message: N_('Netbox disk base unit must be 1000 or 1024'))
    end
  end

  logger :import, enabled: true
end
