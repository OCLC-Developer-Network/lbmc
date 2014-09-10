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
  pass unless request.path_info =~ /record/
  session[:path] = request.path
  authenticate
end

get '/' do
  session[:path] = request.path
  haml :index, :layout => :template
end

get '/record/new' do
  haml :new, :layout => :template
end

post '/record/create' do
  record = marc_record_from_params(params)
  @bib = Bib.new_from_marc(record, session[:token])
  @bib.create
  if @bib.response_code == '201'
    redirect "/record/#{@bib.marc_record['001'].value.gsub(/\D/, '')}"
  else
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
  else 
    haml :error, :layout => :template
  end
end

post '/record/update' do
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
    # If the user's session is gone, go to the home page and have them reselect the authenticating inst ID.
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
  session[:registry_id] = params[:registry_id] if params[:registry_id] 
  if session[:token].nil? or session[:token].expired?
    login_url = WSKEY.login_url(session[:registry_id], session[:registry_id])
    redirect login_url
  end
end

