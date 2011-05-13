require 'rubygems'
require 'bundler/setup'
Bundler.require
Wrong.config.alias_assert :expect
require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib', 'sinatra', 'ska.rb')

raise 'Usage: SIGNED_REQUEST APP_KEY APP_SECRET' if ARGV.length != 3

SIGNED_REQUEST = ARGV[0]
API_KEY = ARGV[1]
APP_SECRET = ARGV[2]

YAML_CONFIG_HASH = {'test' => {'api_key' => API_KEY,
                               'app_secret' => APP_SECRET,
                               'canvas_page_name' => 'test_canvas_page_name',
                               'callback_url' => 'callback_url',
                               'page_id' => 12345,
                               'app_id' => 54321}}
YAML_CONFIG_FILE = Tempfile.new('yaml_config')
YAML_CONFIG_FILE.write YAML.dump(YAML_CONFIG_HASH)
YAML_CONFIG_FILE.close

Sinatra::Ska.load_facebook_config YAML_CONFIG_HASH['test'], :test
PARSED_SIGNED_REQUEST = Sinatra::Ska::SignedRequest.new Koala::Facebook::OAuth.new(Sinatra::Ska.config.api_key, Sinatra::Ska.config.app_secret), SIGNED_REQUEST

include Rack::Test::Methods
def params; {:signed_request => SIGNED_REQUEST} end
def mock_app(base=Sinatra::Base, &block)
  @app = Sinatra.new base, &block
  @app.register Sinatra::Ska
  @app.disable :dump_errors, :show_exceptions 
  @app.enable :raise_errors
end
def app; @app end

describe "A sinatra application running Ska" do
  before do
    Sinatra::Ska.load_facebook_config YAML_CONFIG_HASH['test'], :test
  end
  
  
  it "redirects when no signed request" do
    mock_app {
      get '/?' do
        init_ska
      end
    }
    get '/'
    expect { last_response.ok? }
    expect { last_response.body == %{<script type="text/javascript">top.location.href = "https://graph.facebook.com/oauth/authorize?client_id=#{YAML_CONFIG_HASH['API_KEY']}&redirect_uri=http%3A%2F%2Fapps.facebook.com%2Ftest%2F&scope=";</script>} }
  end
  
=begin
  context 'redirects' do
    test 'when no signed request' do
      get '/'
      assert_equal 200, last_response.status
      assert_equal %{<script type="text/javascript">top.location.href = "https://graph.facebook.com/oauth/authorize?client_id=#{APP_KEY}&redirect_uri=http%3A%2F%2Fapps.facebook.com%2Ftest%2F&scope=";</script>}, last_response.body        
    end

    test 'with permissions string' do
      get '/with_permissions_string'
      assert_equal 200, last_response.status
      assert_equal %{<script type="text/javascript">top.location.href = "https://graph.facebook.com/oauth/authorize?client_id=#{APP_KEY}&redirect_uri=http%3A%2F%2Fapps.facebook.com%2Ftest%2Fwith_permissions_string&scope=permission_one";</script>}, last_response.body
    end

    test 'with permissions array' do
      get '/with_permissions_array'
      assert_equal 200, last_response.status
      assert_equal %{<script type="text/javascript">top.location.href = "https://graph.facebook.com/oauth/authorize?client_id=#{APP_KEY}&redirect_uri=http%3A%2F%2Fapps.facebook.com%2Ftest%2Fwith_permissions_array&scope=permission_one,permission_two";</script>}, last_response.body
    end

  end
=end
  
  
  
  
  
  
  
  it 'returns raw data from api via open graph' do
    mock_app {
      get '/?' do
        init_ska
        @result = ska_graph.get_object('me', :raw => true).to_json
      end
    }
    get '/', :signed_request => SIGNED_REQUEST
    expect { last_response.ok? }
    expect { JSON.parse(last_response.body)['first_name'] }
  end
  
  it "parses signed request properly" do
    mock_app {
      get '/?' do
        init_ska
        ska_signed_request.to_json
      end
    }
    get '/', :signed_request => SIGNED_REQUEST
    signed_request_response = JSON.parse last_response.body
    expect { last_response.ok? }
    expect { signed_request_response['expires'] == PARSED_SIGNED_REQUEST.expires }
    expect { signed_request_response['oauth_token'] == PARSED_SIGNED_REQUEST.oauth_token }
    expect { signed_request_response['user_id'] == PARSED_SIGNED_REQUEST.user_id }
  end
end

describe Sinatra::Ska do
  describe "when given configuration from file" do
    it "must have the config values present" do
      Sinatra::Ska.load_facebook_config YAML_CONFIG_FILE.path, :test
      YAML_CONFIG_HASH['test'].each do |key,value|
        expect { Sinatra::Ska.config.send(key.to_sym) == value }
      end
    end
  end
  
  describe "when given configuration from hash" do
    it "must have the config values present" do
      Sinatra::Ska.load_facebook_config YAML_CONFIG_HASH['test'], :test
      YAML_CONFIG_HASH['test'].each do |key,value|
        expect { Sinatra::Ska.config.send(key.to_sym) == value }
      end
    end
  end
end

describe Sinatra::Ska::FacebookHelpers do
  before do
    Sinatra::Ska.load_facebook_config YAML_CONFIG_HASH['test'], :test
  end
  
  describe "the url_for method" do
    it "correctly provides link for fbml" do
      mock_app {
        get '/' do
          url_for 'widgets'
        end
      }
      get '/'
      expect { last_response.ok? }
      expect { last_response.body == "http://apps.facebook.com/#{Sinatra::Ska.config.canvas_page_name}/widgets" }
    end
    
    it "provides direct url" do
      mock_app {
        get '/' do
          url_for 'widgets', :skip_facebook => true
        end
      }
      get '/'
      expect { last_response.ok? }
      expect { last_response.body == "#{Sinatra::Ska.config.callback_url}/widgets" }
    end
    
    it "ignores forward slash" do
      mock_app {
        get '/' do
          url_for '/widgets'
        end
      }
      get '/'
      expect { last_response.ok? }
      expect { last_response.body == "http://apps.facebook.com/#{Sinatra::Ska.config.canvas_page_name}/widgets" }
    end
  end
  
  describe "the url_for_img method" do
    it "correctly points to image directly on app, allowing for cache-busting suffixes" do
      mock_app {
        get '/' do
          url_for_img 'test.jpg'
        end
      }
      get '/'
      expect { last_response.ok? }
      expect { last_response.body =~ /#{Sinatra::Ska.config.callback_url}\/img\/test.jpg$/ }
    end
  end
  
  describe "the url_for_page_tab method" do
    it "correctly provides the url of the page tab" do
      mock_app {
        get '/' do
          url_for_page_tab
        end
      }
      get '/'
      expect { last_response.ok? }
      expect { last_response.body == Sinatra::Ska.config.page_tab_url }
    end
  end
end