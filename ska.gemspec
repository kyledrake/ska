Gem::Specification.new do |s|
  s.name                      = 'ska'
  s.version                   = '0.0.1'
  s.authors                   = ['Kyle Drake']
  s.email                     = ['kyle.drake@dachisgroup.com']
  s.homepage                  = 'https://github.com/kyledrake/ska'
  s.summary                   = 'Sinatra adapter for Koala'
  s.description               = 'Sinatra adapter for Koala!'
  s.files                     = Dir['{lib,test}/**/*'] + Dir['[A-Z]*']
  s.require_path              = 'lib'
  s.rubyforge_project         = s.name
  s.required_rubygems_version = '>= 1.3.4'
  
  s.add_dependency 'sinatra', >= '1.0'
end