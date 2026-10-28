# frozen_string_literal: true

require File.expand_path('lib/foreman_netbox/version', __dir__)

Gem::Specification.new do |s|
  s.name        = 'foreman_netbox'
  s.version     = ForemanNetbox::VERSION
  s.license     = 'GPL-3.0'
  s.authors     = ['dmTECH GmbH']
  s.email       = ['opensource@dm.de']
  s.homepage    = 'https://github.com/dm-drogeriemarkt/foreman_netbox'
  s.summary     = 'Adds integration with NetBox'

  s.required_ruby_version = '>= 3.0', '< 4'

  s.files = Dir['{app,config,db,lib,locale,webpack}/**/*'] + ['LICENSE', 'Rakefile', 'README.md', 'package.json']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'dry-validation', '>= 1.10', '< 2'
  s.add_dependency 'interactor', '~> 3.1'
  s.add_dependency 'netbox-client-ruby', '~> 0.16'

  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'theforeman-rubocop', '~> 0.1.2'
end
