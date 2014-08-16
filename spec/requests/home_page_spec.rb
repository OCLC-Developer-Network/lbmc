require 'spec_helper'

describe "the home page" do  
  
  describe "after logging in" do
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
