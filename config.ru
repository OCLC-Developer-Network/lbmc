require 'sinatra'
require 'haml'
require 'yaml'
require 'rest_client'
require 'marc'
require 'nokogiri'
require 'json'
require 'oclc/auth'


require './app'
require './model/bib'
require './model/error'
require './helpers/application_helper'

enable :sessions
set :session_secret, '406c8f30ee92'
set :environment, :development
set :run, true
set :raise_errors, true

wskey_config = YAML::load(File.read("#{File.expand_path(File.dirname(__FILE__))}/config/wskey.yml"))
key = wskey_config[settings.environment.to_s]['key']
secret = wskey_config[settings.environment.to_s]['secret']
redirect_uri = wskey_config[settings.environment.to_s]['redirect_uri']
WSKEY = OCLC::Auth::WSKey.new(key, secret, :services => ['WorldCatMetadataAPI'], :redirect_uri => redirect_uri)

config = YAML::load(File.read("#{File.expand_path(File.dirname(__FILE__))}/config/lbmc.yml"))
BASE_URL = config[settings.environment.to_s]['base_url']
INSTITUTIONS = config[settings.environment.to_s]['institutions']

run Sinatra::Application