require "spec_helper"

class TestHelper
  include ApplicationHelper
end

describe ApplicationHelper do
  
  let(:helpers) { TestHelper.new }
  
  context "when updating a MARC record with no publication data" do
    before(:each) do
      raw_marc = StringIO.new( body_content("no_publication_data.marcxml") )
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
      raw_marc = StringIO.new( body_content("publisher_name_only.marcxml") )
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
      raw_marc = StringIO.new( body_content("publication_date_only.marcxml") )
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
      raw_marc = StringIO.new( body_content("all_publication_data.marcxml") )
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