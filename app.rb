set :public_folder, File.dirname(__FILE__) + '/public'
set :views, File.dirname(__FILE__) + "/views"
set :haml, :format => :html5

helpers do
  include ApplicationHelper
end

before do
  # The home page is unauthenticated, it is where the user chooses an institution to login against
  # The user's session does not yet have an access token in his/her session when the app catches an
  # auth code.
  pass if request.path_info == '/' or request.path_info == '/catch_auth_code'
  session[:path] = request.path unless request.path == '/authenticate' or request.path == '/logoff'
  authenticate
end

get '/' do
  haml :index, :layout => :template
end

get '/record/new' do
  haml :new, :layout => :template
end

post '/create' do
  record = marc_record_from_params(params)
  @bib = Bib.new_from_marc(record, session[:token])
  @bib.create
  if @bib.response_code == '201'
    redirect "/record/#{@bib.marc_record['001'].value.gsub(/\D/, '')}"
  else
    haml :new, :layout => :template
  end
end

get '/record/:oclc_number.xml' do
  @bib = Bib.new(params[:oclc_number], session[:token])
  if @bib.response_code == '200' or @bib.response_code == '201'
    haml :record_xml, :content_type => "text/xml"
  else 
    haml :error, :layout => :template
  end
end

get '/record/:oclc_number.marc' do
  @bib = Bib.new(params[:oclc_number], session[:token])
  if @bib.response_code == '200' or @bib.response_code == '201'
    haml :record_marc
  else 
    haml :error, :layout => :template
  end
end

get '/record/:oclc_number' do
  @bib = Bib.new(params[:oclc_number], session[:token])
  if @bib.response_code == '200' or @bib.response_code == '201'
    haml :record, :layout => :template
  else 
    haml :error, :layout => :template
  end
end

post '/update' do
  @bib = Bib.new(params[:oclc_number], session[:token])
  record = update_marc_record_from_params(@bib.marc_record, params)
  @bib.marc_record = record
  @bib.update
  if @bib.response_code == '200' or @bib.response_code == '201'
    redirect "/record/#{@bib.marc_record['001'].value.gsub(/\D/, '')}"
  else
    haml :record, :layout => :template
  end
end

get '/logoff' do
  session[:token] = nil
  session[:path] = "/"
  redirect session[:path]
end

get '/catch_auth_code' do
  if params and params[:code]
    session[:token] = WSKEY.auth_code_token(params[:code], session[:registry_id], session[:registry_id])
    redirect session[:path]
  else
    redirect '/'
    # "This view will only render if there is an error in the login flow. " +
    # "This page renders after the browser is redirected  back to the this app with an " +
    # "error message as a URL parameter."
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
  session[:registry_id] = params[:registry_id] if params[:registry_id] 
  if session[:token].nil? or session[:token].expired?
    login_url = WSKEY.login_url(session[:registry_id], session[:registry_id])
    redirect login_url
  end
end

