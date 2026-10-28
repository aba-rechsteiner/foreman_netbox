# frozen_string_literal: true

require 'dry-validation'
require 'netbox-client-ruby'
require 'interactor'

module ForemanNetbox
  class Engine < ::Rails::Engine
    engine_name 'foreman_netbox'

    # Add any db migrations
    initializer 'foreman_netbox.load_app_instance_data' do |app|
      ForemanNetbox::Engine.paths['db/migrate'].existent.each do |path|
        app.config.paths['db/migrate'] << path
      end
    end

    initializer 'foreman_netbox.register_plugin', before: :finisher_hook do |app|
      app.reloader.to_prepare do
        require 'foreman_netbox/register'
      end
    end

    # Include concerns in this config.to_prepare block
    config.to_prepare do
      ::Host::Managed.include(ForemanNetbox::HostExtensions)
      ::Location.include(ForemanNetbox::LocationExtensions)
      ::Nic::Base.include(ForemanNetbox::Nic::BaseExtensions)
      ::User.include(ForemanNetbox::UserUsergroupCommonExtensions)
      ::Usergroup.include(ForemanNetbox::UserUsergroupCommonExtensions)
    rescue StandardError => e
      Rails.logger.warn "ForemanNetbox: skipping engine hook (#{e})\n#{e.backtrace.join("\n")}"
    end
  end
end
