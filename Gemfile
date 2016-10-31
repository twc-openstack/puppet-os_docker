source 'https://rubygems.org'

gem 'puppetlabs_spec_helper', :require => false
gem 'rspec-puppet', '~> 2.3.0', :require => false

gem 'puppet-lint-absolute_classname-check'
gem 'puppet-lint-absolute_template_path'
gem 'puppet-lint-trailing_newline-check'

gem 'puppet-lint-variable_contains_upcase'
gem 'puppet-lint-leading_zero-check'
gem 'puppet-lint-numericvariable'
gem 'puppet-lint-unquoted_string-check'

gem 'json_pure', '< 2.0.2', :require => false

if puppetversion = ENV['PUPPET_GEM_VERSION']
          gem 'puppet', puppetversion, :require => false
else
          gem 'puppet', :require => false
end

# vim:ft=ruby
