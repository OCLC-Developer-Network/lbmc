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

describe "the home page", multi_institutions: true do
  before do
    config = YAML::load(File.read("#{File.expand_path(File.dirname(__FILE__))}/../../config/lbmc_multi_institutions.yml"))
    $app_url = config[$environment]['app_url']
    $base_url = config[$environment]['base_url']
    $institutions = config[$environment]['institutions']
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
        @ocpsb_login = login_links.find {|element| element if element.attr('id') == 'login-to-128807'}
        @ocwms_login = login_links.find {|element| element if element.attr('id') == 'login-to-91475'}
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
        uri = URI.parse(@ocpsb_login.attr('href'))
        expect(uri.path).to eq("/authenticate")
        expect(uri.query).to eq("registry_id=128807")
        uri = URI.parse(@ocwms_login.attr('href'))
        expect(uri.path).to eq("/authenticate")
        expect(uri.query).to eq("registry_id=91475")
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
