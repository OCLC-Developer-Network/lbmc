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

set :public_folder, File.dirname(__FILE__) + '/public'
set :views, File.dirname(__FILE__) + "/views"
set :haml, :format => :html5

I18n.enforce_available_locales = false
I18n.locale = :en
I18n.default_locale = :en
I18n.load_path << Dir[File.join(File.expand_path(File.dirname(__FILE__) + '/config/locales'), '*.yml')]
I18n.load_path.flatten!

helpers do
  include ApplicationHelper
end

before do
  # The home page is unauthenticated, it is where the user chooses an institution to login against
  # The user's session does not yet have an access token in his/her session when the app catches an
  # auth code.
  # puts ; puts "Before do, request.path_info is " + request.path_info; puts
  # puts ; puts session.inspect ; puts
  set_locale
  if $institutions.count == 1 
    pass if params[:error] || params[:code]
    session[:path] = request.path
    authenticate
  else  
    pass unless request.path_info =~ /record/
    session[:path] = request.path
    authenticate
  end
end

get '/' do
  # puts ; puts "get / " + request.path_info; puts
  session[:path] = request.path
  haml :index, :layout => :template
end

get '/detect/:term' do
  detect_unicode_block(params[:term])
end

get '/record/new' do
  haml :new, :layout => :template
end

post '/record/create' do
  # puts ; puts "get /record/create params[:language]=" + params[:language]; puts
  session[:marc_language] = params[:language]
  record = marc_record_from_params('',params)
  @bib = Bib.new_from_marc(record, session[:token])
  @bib.create
  if @bib.response_code == '201'
    #redirect url("/record/#{@bib.marc_record['001'].value.gsub(/\D/, '')}")
    redirect url("/status/created/#{@bib.marc_record['001'].value.gsub(/\D/, '')}")
  else
    # puts ; puts "get /record/create apply new layout"; puts
    haml :new, :layout => :template
  end
end

get '/record/:oclc_number.?:format?' do
  @bib = Bib.new(params[:oclc_number], session[:token])
  if @bib.response_code == '200' or @bib.response_code == '201'
    if params[:format] == 'xml'
      content_type :xml
      @bib.marc_record.to_xml.to_s
    elsif params[:format] == 'mrc'
      content_type 'application/marc'
      @bib.marc_record.to_marc
    else
      haml :record, :layout => :template
    end
  elsif @bib.response_code == '404'
    haml :not_found, :layout => :template
  else 
    haml :error, :layout => :template
  end
end

post '/record/update' do 
  session[:marc_language] = params[:language]
  @bib = Bib.new(params[:oclc_number], session[:token])
  record = marc_record_from_params(@bib.marc_record, params)
  @bib.marc_record = record
  @bib.update
  if @bib.response_code == '200' or @bib.response_code == '201'
    #redirect url("/record/#{@bib.marc_record['001'].value.gsub(/\D/, '')}")
    redirect url("/status/updated/#{@bib.marc_record['001'].value.gsub(/\D/, '')}")
  else
    haml :record, :layout => :template
  end
end

get '/status/:type/:oclc_number' do
  @bib = Bib.new(params[:oclc_number], session[:token])
  @type = params[:type]
  if @bib.response_code == '200' or @bib.response_code == '201'
    haml :status, :layout => :template
  elsif @bib.response_code == '404'
    haml :not_found, :layout => :template
  else 
    haml :error, :layout => :template
  end
end

get '/logoff' do
  session[:token] = nil
  redirect url("/")
end

get '/catch_auth_code' do
  if params and params[:code]
    session[:token] = WSKEY.auth_code_token(params[:code], session[:registry_id], session[:registry_id])
    redirect session[:path]
  elsif params and params[:error]
    haml :error, :layout => :template 
  else
    redirect url('/')
  end
end

get '/authenticate' do
  authenticate
  redirect session[:path]
end

not_found do
  haml :not_found, :layout => :template
end

error do
  haml :error, :layout => :template
end

def authenticate
  if $institutions.count == 1
    session[:registry_id] = $institutions.keys.first
  else
    session[:registry_id] = params[:registry_id] if params[:registry_id]
  end 
  if session[:token].nil?
    login_url = WSKEY.login_url(session[:registry_id], session[:registry_id])
    redirect login_url
  elsif session[:token].expired?
    login_url = WSKEY.login_url(session[:registry_id], session[:registry_id])
    redirect login_url
  end
end

def set_locale
  unless params[:locale].nil?
    session[:locale] = params[:locale]
  end
  if session[:locale].nil?
    if @env["HTTP_ACCEPT_LANGUAGE"].nil?
      session[:locale] = I18n.default_locale
    else
      session[:locale] = @env["HTTP_ACCEPT_LANGUAGE"][0,2]
    end
    # session[:locale] = I18n.default_locale
  end
  I18n.locale = session[:locale]
end

