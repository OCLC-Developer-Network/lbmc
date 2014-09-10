require 'spec_helper'

describe Bib do

  before(:all) do
    @access_token = OCLC::Auth::AccessToken.new('grant_type', ['FauxService'], 128807, 128807)
    @access_token.value = 'tk_faux_token'
    @access_token.expires_at = DateTime.parse("9999-01-01 00:00:00Z")
  end
  
  context "when loading an error response from the Metadata API" do
    before(:all) do
      stub_request(:post, "http://cataloging-worldcatbib-qa.ent.oclc.org/bib/data?classificationScheme=LibraryOfCongress").
          to_return(:status => 409, :body => mock_file_contents("titleless-input-response.marcxml"))
      
      raw_marc = StringIO.new( mock_file_contents("titleless-input.marcxml") )
      record = MARC::XMLReader.new(raw_marc).first
      @bib = Bib.new_from_marc(record, @access_token)
      @bib.create
    end
    
    it "should have an OCLC error" do
      expect(@bib.error).to be_instance_of(OCLCError)
    end
    
    it "should have the right error summary" do
      expect(@bib.error.summary).to eq('Record is invalid')
    end
    
    it "should have 2 validation errors" do
      expect(@bib.error.validation_errors.size).to eq(2)
    end
    
    context "the first validation error" do
      before(:all) do
        @validation_error = @bib.error.validation_errors.first
      end
    
      it "should have the correct type" do 
        expect(@validation_error.type).to eq('root')
      end

      it "should have the correct field" do 
        expect(@validation_error.field).to eq('REC')
      end

      it "should have the correct occurrence" do 
        expect(@validation_error.occurrence).to eq('1')
      end

      it "should have the correct message" do 
        expect(@validation_error.message).to eq('$a in 245 or $k in 245 must be present.')
      end
    end
  end
  
  context "when testing a record that did not originate in LBMC" do
    before(:all) do
      stub_request(:post, "http://cataloging-worldcatbib-qa.ent.oclc.org/bib/data?classificationScheme=LibraryOfCongress").
          to_return(:status => 200, :body => mock_file_contents("ocm09999999.atomxml"))
      
      raw_marc = StringIO.new( mock_file_contents("ocm9999999.marcxml") )
      record = MARC::XMLReader.new(raw_marc).first
      @bib = Bib.new_from_marc(record, @access_token)
      @bib.create
    end
    
    it "should not indicate it is LBMC app created" do
      expect(@bib.is_app_created?).to be_nil
    end
  end
  
  context "when testing a record that did originate in LBMC" do
    before(:all) do
      stub_request(:post, "http://cataloging-worldcatbib-qa.ent.oclc.org/bib/data?classificationScheme=LibraryOfCongress").
          to_return(:status => 200, :body => mock_file_contents("ocn883876185.atomxml"))
      
      raw_marc = StringIO.new( mock_file_contents("ocn883876185.marcxml") )
      record = MARC::XMLReader.new(raw_marc).first
      @bib = Bib.new_from_marc(record, @access_token)
      @bib.create
    end
    
    it "should indicate it is LBMC app created" do
      expect(@bib.is_app_created?).to be true
    end
  end
  
end