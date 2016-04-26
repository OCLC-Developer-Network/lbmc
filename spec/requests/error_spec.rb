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

describe "the error page" do
  context "when using a WSKey not for WorldCat Metadata API" do
    before(:all) do
      get '/catch_auth_code?error=invalid_client_id&error_description=WSKey+is+invalid&http_code=401', params={}, rack_env={ 'rack.session' => {:registry_id => 128807} }
      @doc = Nokogiri::HTML(last_response.body)
      @form_element = @doc.xpath("//form[@id='record-form']").first
    end

    it "should not display a form" do
      expect(@doc.xpath("//form[@id='record-form']").first).to be_nil
    end
    
    it "should display an alert info message" do
      xpath = "//div[@class='alert alert-danger']"
      expect(@doc.xpath(xpath)).not_to be_empty
    end
    
    it "should display the error section" do
      xpath = "//div[@class='alert alert-danger']/div[@class='pad_above'][contains(text(), 'The WSKey configured for the application is invalid.')]"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
  end
  
  context "when using a WSKey that is not valid" do
    before(:all) do
      get '/catch_auth_code?error=invalid_scope&error_description=Invalid+scope%28s%29%3A+WorldCatMetadataAPI+%28WorldCat+Metadata+API%29+%5BNot+on+key%5D&http_code=403', params={}, rack_env={ 'rack.session' => {:registry_id => 128807} }
      @doc = Nokogiri::HTML(last_response.body)
      @form_element = @doc.xpath("//form[@id='record-form']").first
    end

    it "should not display a form" do
      expect(@doc.xpath("//form[@id='record-form']").first).to be_nil
    end
    
    it "should display an alert info message" do
      xpath = "//div[@class='alert alert-danger']"
      expect(@doc.xpath(xpath)).not_to be_empty
    end
    
    it "should display the error section" do
      xpath = "//div[@class='alert alert-danger']/div[@class='pad_above'][contains(text(), 'The WSKey configured for the application does not have the proper permissions. Please make sure the WSKey is for WorldCat Metadata API')]"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
  end
  
  context "when using an access token that is not valid" do
    before(:all) do
      @access_token = OCLC::Auth::AccessToken.new('grant_type', ['FauxService'], 128807, 128807)
      @access_token.value = 'tk_faux_token'
      @access_token.expires_at = DateTime.parse("9999-01-01 00:00:00Z")
      stub_request(:get, "https://worldcat.org/bib/data/883876185?classificationScheme=LibraryOfCongress").
        to_return(:status => 401, :body => mock_file_contents("access_token_invalid.xml"))
      get '/record/883876185', params={}, rack_env={ 'rack.session' => {:token => @access_token, :registry_id => 128807} }
      @doc = Nokogiri::HTML(last_response.body)
      @form_element = @doc.xpath("//form[@id='record-form']").first
    end

    it "should not display a form" do
      expect(@doc.xpath("//form[@id='record-form']").first).to be_nil
    end
    
    it "should display an alert info message" do
      xpath = "//div[@class='alert alert-danger']"
      expect(@doc.xpath(xpath)).not_to be_empty
    end
    
    it "should display the error section" do
      xpath = "//div[@class='alert alert-danger']/div[@class='pad_above'][contains(text(), 'This system error has been logged and reported to the LBMC development team.  We apologize for the disruption and are working on a solution.')]"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
    
    it "should display the error section with access token message" do
      xpath = "//div[@class='alert alert-danger']/div[@class='pad_above'][contains(text(), 'The Access Token is invalid')]"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
    
  end
  
  context "when using an access token that is not for the right web service" do
    before(:all) do
      @access_token = OCLC::Auth::AccessToken.new('grant_type', ['FauxService'], 128807, 128807)
      @access_token.value = 'tk_faux_token'
      @access_token.expires_at = DateTime.parse("9999-01-01 00:00:00Z")
      stub_request(:get, "https://worldcat.org/bib/data/883876185?classificationScheme=LibraryOfCongress").
        to_return(:status => 403, :body => mock_file_contents("access_token_wrong_service.xml"))
      get '/record/883876185', params={}, rack_env={ 'rack.session' => {:token => @access_token, :registry_id => 128807} }
      @doc = Nokogiri::HTML(last_response.body)
      @form_element = @doc.xpath("//form[@id='record-form']").first
    end

    it "should not display a form" do
      expect(@doc.xpath("//form[@id='record-form']").first).to be_nil
    end
    
    it "should display an alert danger message" do
      xpath = "//div[@class='alert alert-danger']"
      expect(@doc.xpath(xpath)).not_to be_empty
    end
    
    it "should display the error section" do
      xpath = "//div[@class='alert alert-danger']/div[@class='pad_above'][contains(text(), 'This system error has been logged and reported to the LBMC development team.  We apologize for the disruption and are working on a solution.')]"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
    
    it "should display the error section with access token message" do
      xpath = "//div[@class='alert alert-danger']/div[@class='pad_above'][contains(text(), 'The Access Token is for the wrong scope')]"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
    
  end
    
end
