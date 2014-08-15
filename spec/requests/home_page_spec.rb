# require 'spec_helper'
require 'sinatra'
require 'haml'
require 'yaml'
require 'rest_client'
require 'marc'
require 'nokogiri'
require 'json'
require 'oclc/auth'
require "rspec"
require "rack/test"

require File.join(File.dirname(__FILE__), '../..', 'app.rb')
require File.join(File.dirname(__FILE__), '../..', 'helpers/application_helper.rb')
require File.join(File.dirname(__FILE__), '../..', 'model/bib.rb')
require File.join(File.dirname(__FILE__), '../..', 'model/error.rb')

describe "the app" do
  include Rack::Test::Methods
  
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

  describe "after logging in" do
    subject { page }
    before do
      @access_token = OCLC::Auth::AccessToken.new('grant_type', ['FauxService'], 128807, 128807)
      @access_token.value = 'tk_faux_token'
      @access_token.expires_at = DateTime.parse("9999-01-01 00:00:00Z")

      get '/', params={}, rack_env={ 'rack.session' => {:token => @access_token} }
      @doc = Nokogiri::HTML(last_response.body)
    end

    it "should have a link to an existing record" do
      xpath = "//div[@id='get-started']/p/a[@id='test-record']"
      expect(@doc.xpath(xpath)).not_to be_nil #have_xpath(xpath)
    end
  end
end
