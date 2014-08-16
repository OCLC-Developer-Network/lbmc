require 'spec_helper'

describe "the home page" do
  before do
    get '/'
    @doc = Nokogiri::HTML(last_response.body)
  end

  it "should welcome the user" do
    xpath = "//h2[text()='Welcome!']"
    expect(@doc.xpath(xpath)).not_to be_nil
  end
  
  describe "before logging in" do
    context "the web form to login the user" do
      before do
        form_xpath = "//div[@id='get-started']/form"
        @form_element = @doc.xpath(form_xpath)
      end
      
      it "should be present" do
        expect(@form_element).not_to be_nil
      end

      it "should point to the authenticate action" do
        path = URI.parse(@form_element.attr('action').value).path
        expect(path).to eq("/authenticate")
      end
      
      it "should should let the user select the right institutions" do
        option_elements = @form_element.xpath(".//select/option")
        ocpsb_option = option_elements.find {|element| element if element.attr('value') == '128807'}
        ocwms_option = option_elements.find {|element| element if element.attr('value') == '91475'}
        
        expect(ocpsb_option).to_not be_nil
        expect(ocpsb_option.text).to eq('OCLC WorldShare Platform Sandbox Institution (OCPSB)')
        expect(ocwms_option).to_not be_nil
        expect(ocwms_option.text).to eq('OCLC WorldShare Management Services - Library (OCWMS)')
      end
    end
    
  end

  describe "after logging in when an access token is present in the user session" do
    before do
      @access_token = OCLC::Auth::AccessToken.new('grant_type', ['FauxService'], 128807, 128807)
      @access_token.value = 'tk_faux_token'
      @access_token.expires_at = DateTime.parse("9999-01-01 00:00:00Z")

      get '/', params={}, rack_env={ 'rack.session' => {:token => @access_token} }
      @doc = Nokogiri::HTML(last_response.body)
    end

    it "should have a link to an existing record" do
      xpath = "//div[@id='get-started']/p/a[@id='test-record']"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
  end
end
