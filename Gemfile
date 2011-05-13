source :rubygems
gem 'sinatra', :require => 'sinatra/base' # 1.2.3
gem 'koala'                               # 0.10.0
gem 'rack-test', :require => 'rack/test'  # 0.5.7
gem 'minitest', :require => 'minitest/autorun'
gem 'wrong',    :require => 'wrong/adapters/minitest'
gem 'json'

platforms :ruby_18, :jruby do
  gem 'ruby-debug'
end

platforms :ruby_19 do
  gem 'ruby-debug19', :require => 'ruby-debug'
end