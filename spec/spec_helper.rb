require 'rubygems'
require 'sinatra'
# require 'webmock/rspec'

ENV['RACK_ENV'] = 'test'                    # force the environment to 'test'

def app
  Sinatra::Application
end

class SessionData
  def initialize(cookies)
    @cookies = cookies
    @data = cookies['rack.session']
    if @data
      @data = @data.unpack("m*").first
      @data = Marshal.load(@data)
    else
      @data = {}
    end
  end

  def [](key)
    @data[key]
  end

  def []=(key, value)
    @data[key] = value
    session_data = Marshal.dump(@data)
    session_data = [session_data].pack("m*")
    @cookies.merge("rack.session=#{Rack::Utils.escape(session_data)}", URI.parse("//example.org//"))
    raise "session variable not set" unless @cookies['rack.session'] == session_data
  end
end

def session
  SessionData.new(rack_test_session.instance_variable_get(:@rack_mock_session).cookie_jar)
end

# Spork.prefork do
#   require File.join(File.dirname(__FILE__), '..', 'lbmc_app.rb')
#   require File.join(File.dirname(__FILE__), '..', 'helpers/application_helper.rb')
#   require File.join(File.dirname(__FILE__), '..', 'model/bib.rb')
#   require File.join(File.dirname(__FILE__), '..', 'model/error.rb')
#
#   require 'sinatra'
#   require 'haml'
#   require 'yaml'
#   require 'rest_client'
#   require 'marc'
#   require 'nokogiri'
#   require 'json'
#   require 'oclc/auth'
#   require 'rspec'
#   require 'rack/test'
#   require 'capybara'
#   require 'capybara/dsl'
#   require "awesome_print"
#
#   wskey_config = YAML::load(File.read("#{File.expand_path(File.dirname(__FILE__))}/../config/wskey.yml"))
#   key = wskey_config[settings.environment.to_s]['key']
#   secret = wskey_config[settings.environment.to_s]['secret']
#   redirect_uri = wskey_config[settings.environment.to_s]['redirect_uri']
#   WSKEY = OCLC::Auth::WSKey.new(key, secret, :services => ['WorldCatMetadataAPI'], :redirect_uri => redirect_uri)
#
#   puts ; puts WSKEY.inspect ; puts
#
#   config = YAML::load(File.read("#{File.expand_path(File.dirname(__FILE__))}/../config/lbmc.yml"))
#   BASE_URL = config[settings.environment.to_s]['base_url']
#   INSTITUTIONS = config[settings.environment.to_s]['institutions']
#
#   Capybara.app = LBMCApp # Sinatra::Application       # in order to make Capybara work
#   # Capybara.default_driver = :selenium
#
#   # set test environments
#   # set :environment, :test
#   # set :run, false
#   # set :raise_errors, true
#   # set :logging, false
#
#   RSpec.configure do |config|
#     config.run_all_when_everything_filtered = true
#
#     config.include Rack::Test::Methods
#     config.include Capybara::DSL
#   end
#
#   def app
#     # @app ||= Sinatra::Application
#     @app ||= LBMCApp
#   end
# end
#
# Spork.each_run do
# end

