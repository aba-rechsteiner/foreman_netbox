# frozen_string_literal: true

require 'rake/testtask'

# Tests
namespace :test do
  desc 'Test ForemanNetbox'
  Rake::TestTask.new(:foreman_netbox) do |t|
    test_dir = File.join(File.dirname(__FILE__), '../..', 'test')
    t.libs << ['test', test_dir]
    t.pattern = "#{test_dir}/**/*_test.rb"
    t.verbose = true
    t.warning = false
  end
end

Rake::Task[:test].enhance ['test:foreman_netbox']

namespace :foreman_netbox do
  desc <<~DESC
    Synchronize managed hosts with Netbox. Options:
      HOSTS=<search query>  only hosts matching the Foreman search query, e.g. HOSTS='hostgroup = web'
      ONLY_CHANGED=true     only hosts with changes since the last synchronization, hosts that were never
                            synchronized and hosts that failed to synchronize
  DESC
  task sync: :environment do
    result = User.as_anonymous_admin do
      ForemanNetbox::SyncHosts.call(search: ENV['HOSTS'], only_changed: Foreman::Cast.to_bool(ENV['ONLY_CHANGED']))
    end

    result.synchronized.each { |name| puts "#{name}: synchronized" }
    result.failed.each { |name, error| puts "#{name}: failed - #{error}" }
    puts "#{result.synchronized.size} synchronized, #{result.failed.size} failed, #{result.skipped.size} unchanged"
    exit 1 if result.failed.any?
  end

  namespace :sync do
    # Registered with Foreman::Cron, the setting netbox_periodic_sync selects the one that synchronizes
    %w[hourly daily].each do |cadence|
      desc "Synchronize hosts with changes with Netbox, if the periodic synchronization is set to #{cadence}"
      task cadence => :environment do
        ForemanNetbox::SyncHosts.periodic(cadence)
      end
    end
  end
end
