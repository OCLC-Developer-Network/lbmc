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
        :publication_date => '2013',
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
      expect(@record['260']['c']).to eq('2013')
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
    
    context "and inspecting the 008 field value" do
      before(:each) do
        @flde_value = @record['008'].value
      end
      
      it "should have today's date for the first 5 characters" do
        now = Time.now
        year = now.year.to_s[2,2]
        month = now.month.to_s.rjust(2, '0')
        day = now.day.to_s.rjust(2, '0')
        expect(@flde_value[0,6]).to eq("#{year}#{month}#{day}")
      end
      
      it "should specify a single known date" do
        expect(@flde_value[6]).to eq('s')
      end

      it "should have the publication date entered by the user" do
        expect(@flde_value[7,4]).to eq('2013')
      end

      it "should not have a second publication date" do
        expect(@flde_value[11,4]).to eq('    ')
      end
      
      it "should indicate an unknown place of publication" do
        expect(@flde_value[15,3]).to eq('xx ')
      end
      
      it "should indicate no illustrations" do
        expect(@flde_value[18,4]).to eq('    ')
      end

      it "should not specify a target audience" do
        expect(@flde_value[22]).to eq(' ')
      end

      it "should not specify a form" do
        expect(@flde_value[23]).to eq(' ')
      end

      it "should not specify nature of contents" do
        expect(@flde_value[24,4]).to eq('    ')
      end

      it "should indicate the item is not a government publication" do
        expect(@flde_value[28]).to eq(' ')
      end
      
      it "should indicate the item is not a conference publication" do
        expect(@flde_value[29]).to eq('0')
      end
      
      it "should indicate the item is not a festschrift" do
        expect(@flde_value[30]).to eq('0')
      end

      it "should indicate the item is does not have an index" do
        expect(@flde_value[31]).to eq('0')
      end

      it "should not specify a literary form" do
        expect(@flde_value[33]).to eq('u')
      end

      it "should not specify biographical material" do
        expect(@flde_value[34]).to eq(' ')
      end

      it "should default to English language materials" do
        expect(@flde_value[35,3]).to eq('eng')
      end

      it "should indicate a non-modified record" do
        expect(@flde_value[38]).to eq(' ')
      end

      it "should indicate an Other cataloging source" do
        expect(@flde_value[39]).to eq('d')
      end
      
      it "should set the year to the current year if the publication date is not a number" do
        params = @params.dup
        params[:publication_date] = '[2013]'
        record = helpers.marc_record_from_params(params)
        flde_value = record['008'].value
        expect(flde_value[7,4]).to eq(Time.now.year.to_s)
      end
    end
  end
  
  context "when updating a MARC record from params" do
    before(:each) do
      raw_marc = StringIO.new( mock_file_contents("no_publication_data.marcxml") )
      @record = MARC::XMLReader.new(raw_marc).first
      @params = {
        :oclc_symbol => 'OCPSB',
        :title => 'Testing metadata APIs',
        :author => 'Doe, John',
        :author_field => '100',
        :publisher => 'OCLC Press',
        :extent => '190 p.',
        :subject => 'Application Programming Interfaces (APIs)',
        :publication_date => '999',
        :publisher => 'OCLC Press'
      }
      helpers.update_marc_record_from_params(@record, @params)
    end
    
    it "should update the publisher date and the the fixed length data date 1" do
      expect(@record['260']['c']).to eq('999')
      expect(@record['008'].value[7,4]).to eq('0999')
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