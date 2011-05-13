require 'sinatra/base'
require 'yaml'
require 'openssl'
require 'ostruct'
require 'koala'
require File.join(File.expand_path(File.dirname(__FILE__)), 'facebook_helpers')

module Sinatra
  module Ska
    class ConfigError < ArgumentError; end
    
    attr_reader :oauth, :graph, :signed_request

    def self.registered(app)
      app.helpers Ska
      app.register Ska::FacebookHelpers
    end
    
    class SignedRequest < OpenStruct
      def [](key); send key end
      def to_hash; @table end
      alias_method :to_h, :to_hash
      def to_json; @table.to_json end
      def initialize(oauth, signed_request)
        @raw = signed_request
        super oauth.parse_signed_request(signed_request)
      end
    end

    class Config < OpenStruct; end
    def self.config; @@config end

    def self.load_facebook_config(file_string_or_hash, env=ENV['RACK_ENV'])
      @@config = Config.new
      
      case file_string_or_hash
      when String
        raise ConfigError, 'YAML configuration file not found' unless File.exist?(file_string_or_hash)
        config_hash = YAML.load_file(file_string_or_hash)[env.to_s]
      when Hash
        config_hash = file_string_or_hash
      else
        raise ConfigError, 'Cannot load provided configuration data'
      end

      config_hash.keys.each {|key| @@config.send("#{key}=", config_hash[key]) unless config_hash[key].nil?}
      @@config.page_url ||= (@@config.page_id ? "http://www.facebook.com/apps/application.php?id=#{@@config.page_id}" : nil)
      @@config.page_tab_url ||= (@@config.page_id ? "http://www.facebook.com/apps/application.php?v=app_#{@@config.app_id}&id=#{@@config.page_id}" : nil)
    end

    def ska_oauth; @_ska_oauth; end
    def ska_signed_request; @_ska_signed_request; end
    def ska_graph; @_ska_graph; end

    def init_ska(scope='')
      oauth = Koala::Facebook::OAuth.new @@config.api_key, @@config.app_secret, request.url
      redirect oauth.url_for_oauth_code(:permissions => scope) unless params[:signed_request] || session['signed_request']
      signed_request = SignedRequest.new oauth, params[:signed_request] || session['signed_request']
      graph = Koala::Facebook::GraphAPI.new signed_request['oauth_token']
      @_ska_oauth = oauth
      @_ska_signed_request = signed_request
      @_ska_graph = graph
    end

    private

    def set_signed_request_cookie(signed_request, expires)
      response.set_cookie 'signed_request', :value => signed_request, :expires => Time.at(expires.to_f), :path => '/'
    end
  end

  register Ska
end