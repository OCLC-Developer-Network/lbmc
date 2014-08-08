set :public_folder, File.dirname(__FILE__) + '/public'

before do
  pass if %w[catch_auth_code].include? request.path_info.split('/')[1]
  session[:path] = request.path
  authenticate
end

get '/' do
  haml :index, :layout => :template
end

post '/create' do
  record = marc_record_from_params(params)
  @bib = Bib.new_from_marc(record, session[:token])
  @bib.create
  if @bib.response_code == '201'
    redirect "/record/#{@bib.marc_record['001'].value.gsub(/\D/, '')}"
  else
    haml :index, :layout => :template
  end
end

get '/record/:oclc_number' do
  @bib = Bib.new(params[:oclc_number], session[:token])
  haml :record, :layout => :template
end

get '/detect/:term' do
  JSON.parse(detect_language(params[:term]).inspect).to_json
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

get '/catch_auth_code' do
  if params and params[:code]
    session[:token] = WSKEY.auth_code_token(params[:code], 128807, 128807)
    redirect session[:path]
  else
    "This view will only render if there is an error in the login flow. " + 
    "This page renders after the browser is redirected  back to the this app with an " + 
    "error message as a URL parameter."
  end
end

def authenticate
  if session[:token].nil? or session[:token].expired?
    login_url = WSKEY.login_url(128807, 128807)
    redirect login_url
  end
end

