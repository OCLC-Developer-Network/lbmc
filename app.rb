set :public_folder, File.dirname(__FILE__) + '/public'
set :views, File.dirname(__FILE__) + "/views"
set :haml, :format => :html5

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
  pass unless request.path_info =~ /record/
  session[:path] = request.path
  authenticate
end

get '/' do
  # puts ; puts "get / " + request.path_info; puts
  session[:path] = request.path
  haml :index, :layout => :template
end

get '/detect/:term' do
  detect_unicode_block(params[:term])
  #detect_script(params[:term])
end

get '/record/new' do
  # puts ; puts "get /record/new " + request.path_info; puts
  haml :new, :layout => :template
end

post '/record/create' do
  # puts ; puts "get /record/create params[:language]=" + params[:language]; puts
  session[:marc_language] = params[:language]
  record = marc_record_from_params('',params)
  @bib = Bib.new_from_marc(record, session[:token])
  @bib.create
  # puts ; puts "get /record/create @bib.response_code is " + @bib.response_code; puts
  if @bib.response_code == '201'
    # puts ; puts "get /record/create redirect to url /record/#{@bib.marc_record['001'].value.gsub(/\D/, '')}"; puts
    redirect url("/record/#{@bib.marc_record['001'].value.gsub(/\D/, '')}")
  else
    # puts ; puts "get /record/create apply new layout"; puts
    haml :new, :layout => :template
  end
end

get '/record/:oclc_number.?:format?' do
  # puts ; puts "get /record/:oclc_number.?:format? with oclc number " + params[:oclc_number]; puts
  @bib = Bib.new(params[:oclc_number], session[:token])
  # puts ; puts "get /record/:oclc_number.?:format? @bib.response_code is " + @bib.response_code; puts
  if @bib.response_code == '200' or @bib.response_code == '201'
    if params[:format] == 'xml'
      # puts ; puts "get /record/:oclc_number.?:format? format xml"; puts
      content_type :xml
      @bib.marc_record.to_xml.to_s
    elsif params[:format] == 'mrc'
      # puts ; puts "get /record/:oclc_number.?:format? format mrc"; puts
      content_type 'application/marc'
      @bib.marc_record.to_marc
    else
      # puts ; puts "get /record/:oclc_number.?:format? apply record layout"; puts
      haml :record, :layout => :template
    end
  elsif @bib.response_code == '404'
    # puts ; puts "get /record/:oclc_number.?:format? apply not_found layout"; puts
    haml :not_found, :layout => :template
  else 
    # puts ; puts "get /record/:oclc_number.?:format? apply error layout"; puts
    haml :error, :layout => :template
  end
end

post '/record/update' do 
  # puts ; puts "get /record/update params[:language]=" + params[:language]; puts
  session[:marc_language] = params[:language]
  @bib = Bib.new(params[:oclc_number], session[:token])
  record = marc_record_from_params(@bib.marc_record, params)
  @bib.marc_record = record
  @bib.update
  # puts ; puts "get /record/update @bib.response_code is " + @bib.response_code; puts
  if @bib.response_code == '200' or @bib.response_code == '201'
    # puts ; puts "get /record/update redirect to /record/#{@bib.marc_record['001'].value.gsub(/\D/, '')}"; puts
    redirect url("/record/#{@bib.marc_record['001'].value.gsub(/\D/, '')}")
  else
    # puts ; puts "get /record/update apply record layout " + @bib.response_code; puts
    haml :record, :layout => :template
  end
end

get '/logoff' do
  # puts ; puts "get /logoff"; puts
  session[:token] = nil
  redirect url("/")
end

get '/catch_auth_code' do
  if params and params[:code]
    session[:token] = WSKEY.auth_code_token(params[:code], session[:registry_id], session[:registry_id])
    redirect session[:path]
  else
    # If the user's session is gone, go to the home page and have them reselect the authenticating inst ID.
    redirect url('/')
  end
end

get '/authenticate' do
  # puts ; puts "authenticating" ; puts
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
  # puts ; puts "authenticate method" ; puts
  session[:registry_id] = params[:registry_id] if params[:registry_id] 
  if session[:token].nil?
    # puts ; puts "session[:token] is nil" ; puts
    login_url = WSKEY.login_url(session[:registry_id], session[:registry_id])
    redirect login_url
  elsif session[:token].expired?
    # puts ; puts "session[:token].expired" ; puts
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

