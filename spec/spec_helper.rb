# Copyright 2016 OCLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# encoding: utf-8

# Copyright 2016 OCLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'sinatra'
require 'sinatra/partial'
require 'haml'
require 'yaml'
require 'rest_client'
require 'marc'
require 'nokogiri'
require 'json'
require 'oclc/auth'
require 'rspec'
require 'rack/test'
require 'webmock/rspec'
require 'i18n'
require 'i18n/backend/fallbacks'

require File.join(File.dirname(__FILE__), '..', 'helpers/application_helper.rb')
require File.join(File.dirname(__FILE__), '..', 'lib/constants.rb')
require File.join(File.dirname(__FILE__), '..', 'model/bib.rb')
require File.join(File.dirname(__FILE__), '..', 'model/oclc_error.rb')
require File.join(File.dirname(__FILE__), '..', 'model/validation_error.rb')
require File.join(File.dirname(__FILE__), '..', 'app.rb')

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

wskey_config = YAML::load(File.read("#{File.expand_path(File.dirname(__FILE__))}/../config/wskey.yml"))
  
key = wskey_config[settings.environment.to_s]['key']
secret = wskey_config[settings.environment.to_s]['secret']
redirect_uri = wskey_config[settings.environment.to_s]['redirect_uri']
WSKEY = OCLC::Auth::WSKey.new(key, secret, :services => ['WorldCatMetadataAPI'], :redirect_uri => redirect_uri)

MARC_LANGUAGES = YAML::load(File.read("#{File.expand_path(File.dirname(__FILE__))}/../config/marc_languages.yml"))
MARC_COUNTRIES = YAML::load(File.read("#{File.expand_path(File.dirname(__FILE__))}/../config/marc_countries.yml"))
config = YAML::load(File.read("#{File.expand_path(File.dirname(__FILE__))}/../config/lbmc.yml"))
CALENDARS = YAML::load(File.read("#{File.expand_path(File.dirname(__FILE__))}/../config/calendars.yml"))
$app_url = config[settings.environment.to_s]['app_url']
$base_url = config[settings.environment.to_s]['base_url']
$institutions = config[settings.environment.to_s]['institutions']
  
$environment = settings.environment.to_s

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.include Rack::Test::Methods
  config.expect_with(:rspec)
end

def mock_file_contents(filename)
  File.new("#{File.expand_path(File.dirname(__FILE__))}/mocks/#{filename}").read
end
