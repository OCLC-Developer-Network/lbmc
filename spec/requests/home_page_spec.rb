require 'spec_helper'

describe "the home page" do
  before do
    get '/'
    @doc = Nokogiri::HTML(last_response.body)
  end

  it "should welcome the user" do
    xpath = "//h3[text()='Welcome!']"
    expect(@doc.xpath(xpath)).not_to be_empty
  end
  
  describe "before logging in" do
    context "the list to login users" do
      before do
        list_xpath = "//div[@id='get-started']"
        @inst_list_wrapper = @doc.xpath(list_xpath)
        login_links = @inst_list_wrapper.xpath(".//a[@class='list-group-item pilot_list']")
        @zcu_login = login_links.find {|element| element if element.attr('id') == 'login-to-4861'}
        @coo_login = login_links.find {|element| element if element.attr('id') == 'login-to-3913'}
        @ocpsb_login = login_links.find {|element| element if element.attr('id') == 'login-to-128807'}
        @ocwms_login = login_links.find {|element| element if element.attr('id') == 'login-to-91475'}
        @clu_login = login_links.find {|element| element if element.attr('id') == 'login-to-207'}
        @uiu_login = login_links.find {|element| element if element.attr('id') == 'login-to-5415'}
        @yus_login = login_links.find {|element| element if element.attr('id') == 'login-to-544'}
      end
      
      it "should be present only once" do
        expect(@inst_list_wrapper).not_to be_nil
        expect(@inst_list_wrapper.size).to eq(1)
      end

      it "should let the user select the right institutions" do
        expect(@ocpsb_login).to_not be_nil
        expect(@ocpsb_login.xpath(".//span").text).to eq('OCLC WorldShare Platform Sandbox Institution')
        expect(@ocwms_login).to_not be_nil
        expect(@ocwms_login.xpath(".//span").text).to eq('OCLC WorldShare Management Services - Library')
      end

      it "should have links that log users in to the correct institutions" do
        uri = URI.parse(@zcu_login.attr('href'))
        expect(uri.path).to eq("/authenticate")
        expect(uri.query).to eq("registry_id=4861")
        uri = URI.parse(@coo_login.attr('href'))
        expect(uri.path).to eq("/authenticate")
        expect(uri.query).to eq("registry_id=3913")
        uri = URI.parse(@ocpsb_login.attr('href'))
        expect(uri.path).to eq("/authenticate")
        expect(uri.query).to eq("registry_id=128807")
        uri = URI.parse(@ocwms_login.attr('href'))
        expect(uri.path).to eq("/authenticate")
        expect(uri.query).to eq("registry_id=91475")
        uri = URI.parse(@clu_login.attr('href'))
        expect(uri.path).to eq("/authenticate")
        expect(uri.query).to eq("registry_id=207")
        uri = URI.parse(@uiu_login.attr('href'))
        expect(uri.path).to eq("/authenticate")
        expect(uri.query).to eq("registry_id=5415")
        uri = URI.parse(@yus_login.attr('href'))
        expect(uri.path).to eq("/authenticate")
        expect(uri.query).to eq("registry_id=544")
      end
      
    end
    
  end

  describe "after logging in when an access token is present in the user session" do
    before do
      access_token = OCLC::Auth::AccessToken.new('grant_type', ['FauxService'], 128807, 128807)
      access_token.value = 'tk_faux_token'
      access_token.expires_at = DateTime.parse("9999-01-01 00:00:00Z")

      get '/', params={}, rack_env={ 'rack.session' => {:token => access_token, :registry_id => 128807} }
      @doc = Nokogiri::HTML(last_response.body)
    end

    it "should have a link to create a new record" do
      xpath = "//a[@id='new-record']"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
    
    it "should have a link to logoff" do
      xpath = "//a[@id='logoff']"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
    
    it "should have hints for new users" do
      xpath = "//h4[text()='Hints for new users']"
      expect(@doc.xpath(xpath)).not_to be_empty
    end
    
  end
end
