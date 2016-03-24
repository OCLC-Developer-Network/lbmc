# encoding: utf-8
require 'sinatra'
require 'sinatra/partial'
require 'haml'
require 'yaml'
require 'rest_client'
require 'marc'
require 'nokogiri'
require 'json'
require 'oclc/auth'
require 'pp'
require 'i18n'
require 'i18n/backend/fallbacks'

require './helpers/application_helper'
require './lib/constants'
require './model/bib'
require './model/oclc_error'
require './model/validation_error'
require './app'

enable :sessions
set :session_secret, '406c8f30ee92'
set :environment, :production
set :run, true
set :raise_errors, true

wskey_config = YAML::load(File.read("#{File.expand_path(File.dirname(__FILE__))}/config/wskey.yml"))
key = wskey_config[settings.environment.to_s]['key']
secret = wskey_config[settings.environment.to_s]['secret']
redirect_uri = wskey_config[settings.environment.to_s]['redirect_uri']
WSKEY = OCLC::Auth::WSKey.new(key, secret, :services => ['WorldCatMetadataAPI'], :redirect_uri => redirect_uri)

config = YAML::load(File.read("#{File.expand_path(File.dirname(__FILE__))}/config/lbmc.yml"))
MARC_LANGUAGES = YAML::load(File.read("#{File.expand_path(File.dirname(__FILE__))}/config/marc_languages.yml"))
MARC_COUNTRIES = YAML::load(File.read("#{File.expand_path(File.dirname(__FILE__))}/config/marc_countries.yml"))
CALENDARS = YAML::load(File.read("#{File.expand_path(File.dirname(__FILE__))}/config/calendars.yml"))
WSKEY_URL = config[settings.environment.to_s]['wskey_url']
$app_url = config[settings.environment.to_s]['app_url']
$base_url = config[settings.environment.to_s]['base_url']
$institutions = config[settings.environment.to_s]['institutions']

run Sinatra::Application