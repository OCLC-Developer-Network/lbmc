require "spec_helper"

class TestHelper
  include ApplicationHelper
end

describe ApplicationHelper do
  
  let(:helpers) { TestHelper.new }
  
  context "when creating a new MARC record" do
    before(:each) do
      @params = {
        :oclc_symbol => 'OCPSB',
        :title => 'Testing metadata APIs',
        :author => 'Doe, John',
        :author_field => '100',
        :publisher => 'OCLC Press',
        :extent => '190 p.',
        :subject => 'Application Programming Interfaces (APIs)',
        :publication_date => '2014',
        :publisher => 'OCLC Press'
      }
      @record = helpers.marc_record_from_params(@params)
    end
    
    it "should have the symbol" do
      expect(@record['040']['a']).to eq('OCPSB')
      expect(@record['040']['c']).to eq('OCPSB')
    end
    
    it "should add the title" do
      expect(@record['245']['a']).to eq('Testing metadata APIs')
    end
  
    it "should add the publisher name" do
      expect(@record['260']['b']).to eq('OCLC Press')
    end

    it "should add the publication date" do
      expect(@record['260']['c']).to eq('2014')
    end
    
    it "should add the extent" do
      expect(@record['300']['a']).to eq('190 p.')
    end
    
    it "should add the LBMC note" do
      expect(@record['500']['a']).to eq(LBMC::SOURCE_NOTE)
    end

    it "should add the subject" do
      expect(@record['650']['a']).to eq('Application Programming Interfaces (APIs)')
    end

    it "should add the author name" do
      expect(@record['100']['a']).to eq('Doe, John')
    end
    
    it "should add an organizational author" do
      params = @params.dup
      params[:author_field] = '110'
      params[:author] = 'OCLC Research'
      @record = helpers.marc_record_from_params(params)
      expect(@record['100']).to be_nil
      expect(@record['110']['a']).to eq('OCLC Research')
    end
  end
  
  context "when updating a MARC record with no publication data" do
    before(:each) do
      raw_marc = StringIO.new( mock_file_contents("no_publication_data.marcxml") )
      @record = MARC::XMLReader.new(raw_marc).first
    end
    
    it "should update the publisher name field alone" do
      helpers.update_field_value(@record, '260', 'b', ' ', ' ', 'OCLC Press')
      expect(@record['260']['b']).to eq('OCLC Press')
    end

    it "should update the publication date field alone" do
      helpers.update_field_value(@record, '260', 'c', ' ', ' ', '2014')
      expect(@record['260']['c']).to eq('2014')
    end
    
    it "should update both publication date and publisher fields" do
      helpers.update_field_value(@record, '260', 'b', ' ', ' ', 'OCLC Press')
      helpers.update_field_value(@record, '260', 'c', ' ', ' ', '2014')
      expect(@record['260']['b']).to eq('OCLC Press')
      expect(@record['260']['c']).to eq('2014')
    end
  end # when testing updates to publication data when none exists
  
  context "when updating a MARC record with publisher name only" do
    before(:each) do
      raw_marc = StringIO.new( mock_file_contents("publisher_name_only.marcxml") )
      @record = MARC::XMLReader.new(raw_marc).first
    end
    
    it "should update the publisher name" do
      expect(@record['260']['b']).to eq('OCLC Press')
      helpers.update_field_value(@record, '260', 'b', ' ', ' ', 'Acme University Press')
      expect(@record['260']['b']).to eq('Acme University Press')
    end

    it "should add the publication date" do
      expect(@record['260']['c']).to be_nil
      helpers.update_field_value(@record, '260', 'c', ' ', ' ', '2014')
      expect(@record['260']['c']).to eq('2014')
    end

    it "should remove the publisher name and the 260 field" do
      expect(@record['260']['b']).to eq('OCLC Press')
      helpers.update_field_value(@record, '260', 'b', ' ', ' ', '')
      expect(@record['260']).to be_nil
    end
  end
  
  context "when updating a MARC record with publication date only" do
    before(:each) do
      raw_marc = StringIO.new( mock_file_contents("publication_date_only.marcxml") )
      @record = MARC::XMLReader.new(raw_marc).first
    end
    
    it "should update the publication date" do
      expect(@record['260']['c']).to eq('2014')
      helpers.update_field_value(@record, '260', 'c', ' ', ' ', '2013')
      expect(@record['260']['c']).to eq('2013')
    end

    it "should add the publisher name" do
      expect(@record['260']['b']).to be_nil
      helpers.update_field_value(@record, '260', 'b', ' ', ' ', 'OCLC Press')
      expect(@record['260']['b']).to eq('OCLC Press')
    end

    it "should remove the publisher name and the 260 field" do
      expect(@record['260']['c']).to eq('2014')
      helpers.update_field_value(@record, '260', 'c', ' ', ' ', '')
      expect(@record['260']).to be_nil
    end
  end
  
  context "when updating a MARC record with all publication data" do
    before(:each) do
      raw_marc = StringIO.new( mock_file_contents("all_publication_data.marcxml") )
      @record = MARC::XMLReader.new(raw_marc).first
    end
    
    it "should update the publication date" do
      expect(@record['260']['b']).to eq('OCLC Press')
      expect(@record['260']['c']).to eq('2014')
      helpers.update_field_value(@record, '260', 'c', ' ', ' ', '2013')
      expect(@record['260']['c']).to eq('2013')
      expect(@record['260']['b']).to eq('OCLC Press')
    end

    it "should update the publisher name" do
      expect(@record['260']['b']).to eq('OCLC Press')
      expect(@record['260']['c']).to eq('2014')
      helpers.update_field_value(@record, '260', 'b', ' ', ' ', 'Acme University Press')
      expect(@record['260']['c']).to eq('2014')
      expect(@record['260']['b']).to eq('Acme University Press')
    end

    it "should remove the publisher name but not the 260 field" do
      expect(@record['260']['b']).to eq('OCLC Press')
      expect(@record['260']['c']).to eq('2014')
      helpers.update_field_value(@record, '260', 'c', ' ', ' ', '')
      expect(@record['260']['c']).to be_nil
      expect(@record['260']['b']).to eq('OCLC Press')
    end

    it "should remove the publication date but not the 260 field" do
      expect(@record['260']['b']).to eq('OCLC Press')
      expect(@record['260']['c']).to eq('2014')
      helpers.update_field_value(@record, '260', 'b', ' ', ' ', '')
      expect(@record['260']['b']).to be_nil
      expect(@record['260']['c']).to eq('2014')
    end

    it "should remove the publication date, publisher name and the 260 field" do
      expect(@record['260']['b']).to eq('OCLC Press')
      expect(@record['260']['c']).to eq('2014')
      helpers.update_field_value(@record, '260', 'b', ' ', ' ', '')
      helpers.update_field_value(@record, '260', 'c', ' ', ' ', '')
      expect(@record['260']).to be_nil
    end
  end
  
end