# frozen_string_literal: true

module ForemanNetbox
  # Synchronizes multiple hosts with Netbox, used by the rake task and the periodic synchronization
  class SyncHosts
    Result = Struct.new(:synchronized, :failed, :skipped, keyword_init: true)

    def self.call(search: nil, only_changed: false)
      new(search: search, only_changed: only_changed).call
    end

    # Run by the cron tasks foreman_netbox:sync:<cadence>, the setting netbox_periodic_sync selects the cadence
    def self.periodic(cadence)
      return unless Setting[:netbox_periodic_sync] == cadence

      result = User.as_anonymous_admin { call(only_changed: true) }
      failed_hosts = " (#{result.failed.keys.join(', ')})" if result.failed.any?
      ::Foreman::Logging.logger('foreman_netbox/import').info(
        "Periodic Netbox synchronization: #{result.synchronized.size} synchronized, " \
        "#{result.failed.size} failed#{failed_hosts}, #{result.skipped.size} unchanged"
      )
      result
    end

    def initialize(search:, only_changed:)
      @search = search
      @only_changed = only_changed
    end

    def call
      result = Result.new(synchronized: [], failed: {}, skipped: [])

      hosts.find_each do |host|
        if only_changed && !needs_synchronization?(host)
          result.skipped << host.name
          next
        end

        sync(host, result)
      end

      result
    end

    private

    attr_reader :search, :only_changed

    # like the orchestration, only managed hosts are synchronized
    def hosts
      scope = Host::Managed.where(managed: true)
      search.present? ? scope.search_for(search) : scope
    end

    def needs_synchronization?(host)
      netbox_facet = host.netbox_facet

      netbox_facet.synchronized_at.nil? || netbox_facet.synchronization_error.present? || netbox_facet.netbox_will_change?
    end

    def sync(host, result)
      sync_result = host.push_to_netbox

      if sync_result.success?
        result.synchronized << host.name
      else
        result.failed[host.name] = sync_result.error
      end
    rescue StandardError => e
      ::Foreman::Logging.logger('foreman_netbox/import').error("Failed to push #{host.name} to Netbox. Error #{e}: #{e.backtrace}")
      result.failed[host.name] = e.message
    end
  end
end
