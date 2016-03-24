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

require 'spec_helper'

I18n.locale = :en
I18n.default_locale = :en
I18n.load_path << Dir[File.join(File.expand_path(File.expand_path(File.dirname(__FILE__)) + '/../config/locales'), '*.yml')]
I18n.load_path.flatten!

describe "the home page" do
  
  describe "before logging in" do
    it "should redirect to login" do
      get '/'
      @oauth_url = 'https://authn.sd00.worldcat.org/oauth2/authorizeCode?authenticatingInstitutionId=128807&client_id=' + WSKEY.key + '&contextInstitutionId=128807'
      @oauth_url += '&redirect_uri=' + Rack::Utils.escape(APP_URL + '/catch_auth_code') + '&response_type=code&scope=WorldCatMetadataAPI'
      expect(last_response).to be_redirect
      expect(last_response.location).to eql(@oauth_url) 
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
    
    it "should welcome the user" do
      xpath = "//h3[text()='Welcome!']"
      expect(@doc.xpath(xpath)).not_to be_empty
    end

    it "should have a link to create a new record" do
      xpath = "//a[@id='new-record']"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
    
    it "should have a link to the home page" do
      xpath = "//a[@id='home']"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
    
    it "should have a link to create a new record" do
      xpath = "//a[@id='create']"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
    
    it "should have a link to logoff" do
      xpath = "//a[@id='logoff']"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
    
    it "should have hints for new users" do
      xpath = "//span[text()='Hints for new users']"
      expect(@doc.xpath(xpath)).not_to be_empty
    end
    
  end
end
