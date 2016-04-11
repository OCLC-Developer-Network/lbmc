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

# encoding: utf-8

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
        :language => 'eng',
        :country_of_publication => 'nyu',
        :title => 'Testing metadata APIs',
        :author => ['Doe, John'],
        :author_field_0 => '100',
        :place_of_publication => 'New York, N.Y.',
        :publisher => 'OCLC Press',
        :extent => '190 p.',
        :subject => ['Application Programming Interfaces (APIs)'],
        :subject_raw => ['$aApplication Programming Interfaces (APIs)'],
        :subject_type => ['653'],
        :subject_id => ['none'],
        :subject_indicator => [' '],
        :publication_date => '2013',
        :isbn => ['9780060723804']
      }
      @record = helpers.marc_record_from_params('',@params)
    end
    
    it "should have the symbol" do
      expect(@record['040']['a']).to eq('OCPSB')
      expect(@record['040']['c']).to eq('OCPSB')
      expect(@record['040'].indicator1).to eq(' ') 
      expect(@record['040'].indicator2).to eq(' ')
    end
    
    it "should add the title" do
      expect(@record['245']['a']).to eq('Testing metadata APIs')
      expect(@record['245'].indicator1).to eq('1') 
      expect(@record['245'].indicator2).to eq('0')
    end
    
    it "should add the place of publication" do
      expect(@record['264']['a']).to eq('New York, N.Y.')
      expect(@record['264'].indicator1).to eq(' ') 
      expect(@record['264'].indicator2).to eq('1')
    end
  
    it "should add the publisher name" do
      expect(@record['264']['b']).to eq('OCLC Press')
      expect(@record['264'].indicator1).to eq(' ') 
      expect(@record['264'].indicator2).to eq('1')
    end

    it "should add the publication date" do
      expect(@record['264']['c']).to eq('2013')
      expect(@record['264'].indicator1).to eq(' ') 
      expect(@record['264'].indicator2).to eq('1')
    end
    
    it "should add the extent" do
      expect(@record['300']['a']).to eq('190 p.')
      expect(@record['300'].indicator1).to eq(' ') 
      expect(@record['300'].indicator2).to eq(' ')
    end
    
    it "should add the LBMC note" do
      expect(@record['500']['a']).to eq(LBMC::SOURCE_NOTE)
      expect(@record['500'].indicator1).to eq(' ') 
      expect(@record['500'].indicator2).to eq(' ')
    end

    it "should add the subject" do
      expect(@record['653']['a']).to eq('Application Programming Interfaces (APIs)')
      expect(@record['653'].indicator1).to eq('0') 
      expect(@record['653'].indicator2).to eq(' ')
    end
    
    it "should add the isbn" do
      expect(@record['020']['a']).to eq('9780060723804')
      expect(@record['020'].indicator1).to eq(' ') 
      expect(@record['020'].indicator2).to eq(' ')
    end

    it "should add the author name" do
      expect(@record['100']['a']).to eq('Doe, John')
      expect(@record['100'].indicator1).to eq('1') 
      expect(@record['100'].indicator2).to eq(' ')
    end
    
    it "should add an organizational author" do
      params = @params.dup
      params[:author_field_0] = '110'
      params[:author] = ['OCLC Research']
      @record = helpers.marc_record_from_params('',params)
      expect(@record['100']).to be_nil
      expect(@record['110']['a']).to eq('OCLC Research')
      expect(@record['110'].indicator1).to eq('2') 
      expect(@record['110'].indicator2).to eq(' ')
    end
    
    it "should set 245 first indicator to 0 if there isn't an author" do
      params = @params.dup
      params[:author_field_0] = '100'
      params[:author] = []
      @record = helpers.marc_record_from_params('',params)
      expect(@record['245'].indicator1).to eq('0')
      expect(@record['245'].indicator2).to eq('0')
    end
    
    it "should set 245 first indicator to 1 if there is an author" do
      params = @params.dup
      params[:author_field_0] = '110'
      params[:author] = ['OCLC Research']
      @record = helpers.marc_record_from_params('',params)
      expect(@record['245'].indicator1).to eq('1')
      expect(@record['245'].indicator2).to eq('0')
      expect(@record['110']['a']).to eq('OCLC Research')
      expect(@record['110'].indicator1).to eq('2') 
      expect(@record['110'].indicator2).to eq(' ')
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
      
      it "should indicate nyu as place of publication" do
        expect(@flde_value[15,3]).to eq('nyu')
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

      it "should have the language provided by the user" do
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
        record = helpers.marc_record_from_params('',params)
        flde_value = record['008'].value
        expect(flde_value[7,4]).to eq(Time.now.year.to_s)
      end
      
      it "should set the publication date using pd1 if available and the calendar is not gregorian" do
        params = @params.dup
        params[:publication_date] = '1435 Islamic Calendar'
        params[:calendar_select] = 'islamic'
        params[:pd1] = '2013'
        record = helpers.marc_record_from_params('',params)
        flde_value = record['008'].value
        expect(flde_value[7,4]).to eq("201u")
      end
      
    end
    
  end
  
  context "when updating a MARC record from params" do
    before(:each) do
      raw_marc = StringIO.new( mock_file_contents("no_publication_data.marcxml") )
      @record = MARC::XMLReader.new(raw_marc).first
      @params = {
        :oclc_symbol => 'OCPSB',
        :language => 'eng',
        :country_of_publication => 'nyu',
        :title => 'Testing metadata APIs',
        :author => ['Doe, John'],
        :author_field_0 => '100',
        :publisher => 'OCLC Press',
        :extent => '190 p.',
        :subject => ['Application Programming Interfaces (APIs)'],
        :subject_raw => ['$aApplication Programming Interfaces (APIs)'],
        :subject_type => ['653'],
        :subject_id => ['none'],
        :subject_indicator => [' '],
        :publication_date => '999'
      }
      helpers.marc_record_from_params(@record, @params)
    end
    
    it "should update the publisher date and the fixed length data date 1" do
      expect(@record['264']['c']).to eq('999')
      expect(@record['264'].indicator1).to eq(' ') 
      expect(@record['264'].indicator2).to eq('1')
      expect(@record['008'].value[7,4]).to eq('0999')
    end

    it "should set 245 first indicator to 0 if there isn't an author" do
      params = @params.dup
      params[:author_field_0] = '100'
      params[:author] = ''
      @record = helpers.marc_record_from_params(@record, params)
      expect(@record['245'].indicator1).to eq('0')
      expect(@record['245'].indicator2).to eq('0')
    end
    
    it "should set 245 first indicator to 1 if there is an author" do
      params = @params.dup
      params[:author_field_0] = '110'
      params[:author] = ['OCLC Research']
      @record = helpers.marc_record_from_params(@record, params)
      expect(@record['245'].indicator1).to eq('1')
      expect(@record['245'].indicator2).to eq('0')
      expect(@record['110']['a']).to eq('OCLC Research')
      expect(@record['110'].indicator1).to eq('2')
      expect(@record['110'].indicator2).to eq(' ')
    end
    
  end
  
  context "when updating a MARC record with no publication data" do
    before(:each) do
      raw_marc = StringIO.new( mock_file_contents("no_publication_data.marcxml") )
      @record = MARC::XMLReader.new(raw_marc).first
    end
    
    it "should update the place of publication field alone" do
      field_tag = '264'
      field_array = Array.new
      subfield_hash = Hash.new
      subfield_hash['a'] = 'Dublin, OH'
      field_hash = helpers.create_field_hash('a', ' ', '1', subfield_hash)
      field_array.push(field_hash)
      helpers.update_field(@record, field_tag, field_array)
      expect(@record['264']['a']).to eq('Dublin, OH')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
    end
    
    it "should update the publisher name field alone" do
      field_tag = '264'
      field_array = Array.new
      subfield_hash = Hash.new
      subfield_hash['b'] = 'OCLC Press'
      field_hash = helpers.create_field_hash('b', ' ', '1', subfield_hash)
      field_array.push(field_hash)
      helpers.update_field(@record, field_tag, field_array)
      expect(@record['264']['b']).to eq('OCLC Press')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
    end

    it "should update the publication date field alone" do
      field_tag = '264'
      field_array = Array.new
      subfield_hash = Hash.new
      subfield_hash['c'] = '2014'
      field_hash = helpers.create_field_hash('c', ' ', '1', subfield_hash)
      field_array.push(field_hash)
      helpers.update_field(@record, field_tag, field_array)
      expect(@record['264']['c']).to eq('2014')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
    end
    
    it "should update all publication fields" do
      field_tag = '264'
      field_array = Array.new
      subfield_hash = Hash.new
      subfield_hash['a'] = 'Dublin, OH'
      subfield_hash['b'] = 'OCLC Press'
      subfield_hash['c'] = '2014'
      field_hash = helpers.create_field_hash('a', ' ', '1', subfield_hash)
      field_array.push(field_hash)
      helpers.update_field(@record, field_tag, field_array)
      expect(@record['264']['a']).to eq('Dublin, OH')
      expect(@record['264']['b']).to eq('OCLC Press')
      expect(@record['264']['c']).to eq('2014')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
    end
  end # when testing updates to publication data when none exists
  
  context "when updating a MARC record with publisher name only" do
    before(:each) do
      raw_marc = StringIO.new( mock_file_contents("publisher_name_only.marcxml") )
      @record = MARC::XMLReader.new(raw_marc).first
    end
    
    it "should update the publisher name" do
      expect(@record['264']['b']).to eq('OCLC Press')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
      field_tag = '264'
      field_array = Array.new
      subfield_hash = Hash.new
      subfield_hash['b'] = 'Acme University Press'
      field_hash = helpers.create_field_hash('b', ' ', '1', subfield_hash)
      field_array.push(field_hash)
      helpers.update_field(@record, field_tag, field_array)
      expect(@record['264']['b']).to eq('Acme University Press')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
    end
    
    it "should add the place of publication" do
      expect(@record['264']['a']).to be_nil
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
      field_tag = '264'
      field_array = Array.new
      subfield_hash = Hash.new
      subfield_hash['a'] = 'Dublin, OH'
      field_hash = helpers.create_field_hash('b', ' ', '1', subfield_hash)
      field_array.push(field_hash)
      helpers.update_field(@record, field_tag, field_array)
      expect(@record['264']['a']).to eq('Dublin, OH')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
    end

    it "should add the publication date" do
      expect(@record['264']['c']).to be_nil
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
      field_tag = '264'
      field_array = Array.new
      subfield_hash = Hash.new
      subfield_hash['c'] = '2014'
      field_hash = helpers.create_field_hash('c', ' ', '1', subfield_hash)
      field_array.push(field_hash)
      helpers.update_field(@record, field_tag, field_array)
      expect(@record['264']['c']).to eq('2014')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
    end

    it "should remove the publisher name and the 264 field" do
      expect(@record['264']['b']).to eq('OCLC Press')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
      field_tag = '264'
      field_array = Array.new
      subfield_hash = Hash.new
      field_hash = helpers.create_field_hash('', ' ', '1', subfield_hash)
      field_array.push(field_hash)
      helpers.update_field(@record, field_tag, field_array)
      expect(@record['264']).to be_nil
    end
  end
  
  context "when updating a MARC record with publication date only" do
    before(:each) do
      raw_marc = StringIO.new( mock_file_contents("publication_date_only.marcxml") )
      @record = MARC::XMLReader.new(raw_marc).first
    end
    
    it "should update the publication date" do
      expect(@record['264']['c']).to eq('2014')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
      field_tag = '264'
      field_array = Array.new
      subfield_hash = Hash.new
      subfield_hash['c'] = '2013'
      field_hash = helpers.create_field_hash('c', ' ', '1', subfield_hash)
      field_array.push(field_hash)
      helpers.update_field(@record, field_tag, field_array)
      expect(@record['264']['c']).to eq('2013')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
    end
    
    it "should add the place of publication" do
      expect(@record['264']['a']).to be_nil
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
      field_tag = '264'
      field_array = Array.new
      subfield_hash = Hash.new
      subfield_hash['a'] = 'Dublin, OH'
      field_hash = helpers.create_field_hash('a', ' ', '1', subfield_hash)
      field_array.push(field_hash)
      helpers.update_field(@record, field_tag, field_array)
      expect(@record['264']['a']).to eq('Dublin, OH')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
    end

    it "should add the publisher name" do
      expect(@record['264']['b']).to be_nil
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
      field_tag = '264'
      field_array = Array.new
      subfield_hash = Hash.new
      subfield_hash['b'] = 'OCLC Press'
      field_hash = helpers.create_field_hash('c', ' ', '1', subfield_hash)
      field_array.push(field_hash)
      helpers.update_field(@record, field_tag, field_array)
      expect(@record['264']['b']).to eq('OCLC Press')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
    end

    it "should remove the publisher name and the 264 field" do
      expect(@record['264']['c']).to eq('2014')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
      field_tag = '264'
      field_array = Array.new
      subfield_hash = Hash.new
      field_hash = helpers.create_field_hash('c', ' ', '1', subfield_hash)
      field_array.push(field_hash)
      helpers.update_field(@record, field_tag, field_array)
      expect(@record['264']).to be_nil
    end
    
    it "should put the imprint subfields in alphabetical order" do
      expect(@record['264'].subfields.first.code).to eq('c')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
      field_tag = '264'
      field_array = Array.new
      subfield_hash = Hash.new
      subfield_hash['b'] = 'OCLC Press'
      field_hash = helpers.create_field_hash('b', ' ', '1', subfield_hash)
      field_array.push(field_hash)
      helpers.update_field(@record, field_tag, field_array)
      expect(@record['264'].subfields.first.code).to eq('b')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
    end
  end
  
  context "when updating a MARC record with all publication data" do
    before(:each) do
      raw_marc = StringIO.new( mock_file_contents("all_publication_data.marcxml") )
      @record = MARC::XMLReader.new(raw_marc).first
    end
    
    it "should update the place of publication" do
      expect(@record['264']['a']).to eq('Dublin, OH')
      expect(@record['264']['b']).to eq('OCLC Press')
      expect(@record['264']['c']).to eq('2014')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
      field_tag = '264'
      field_array = Array.new
      subfield_hash = Hash.new
      subfield_hash['a'] = 'New York, NY'
      subfield_hash['b'] = 'OCLC Press'
      subfield_hash['c'] = '2014'
      field_hash = helpers.create_field_hash('a', ' ', '1', subfield_hash)
      field_array.push(field_hash)
      helpers.update_field(@record, field_tag, field_array)
      expect(@record['264']['a']).to eq('New York, NY')
      expect(@record['264']['b']).to eq('OCLC Press')
      expect(@record['264']['c']).to eq('2014')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
    end
    
    it "should update the publication date" do
      expect(@record['264']['a']).to eq('Dublin, OH')
      expect(@record['264']['b']).to eq('OCLC Press')
      expect(@record['264']['c']).to eq('2014')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
      field_tag = '264'
      field_array = Array.new
      subfield_hash = Hash.new
      subfield_hash['a'] = 'Dublin, OH'
      subfield_hash['b'] = 'OCLC Press'
      subfield_hash['c'] = '2013'
      field_hash = helpers.create_field_hash('a', ' ', '1', subfield_hash)
      field_array.push(field_hash)
      helpers.update_field(@record, field_tag, field_array)
      expect(@record['264']['a']).to eq('Dublin, OH')
      expect(@record['264']['b']).to eq('OCLC Press')
      expect(@record['264']['c']).to eq('2013')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
    end

    it "should update the publisher name" do
      expect(@record['264']['a']).to eq('Dublin, OH')
      expect(@record['264']['b']).to eq('OCLC Press')
      expect(@record['264']['c']).to eq('2014')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
      field_tag = '264'
      field_array = Array.new
      subfield_hash = Hash.new
      subfield_hash['a'] = 'Dublin, OH'
      subfield_hash['b'] = 'Acme University Press'
      subfield_hash['c'] = '2014'
      field_hash = helpers.create_field_hash('a', ' ', '1', subfield_hash)
      field_array.push(field_hash)
      helpers.update_field(@record, field_tag, field_array)
      expect(@record['264']['a']).to eq('Dublin, OH')
      expect(@record['264']['b']).to eq('Acme University Press')
      expect(@record['264']['c']).to eq('2014')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
    end
    
    it "should remove the place of publication but not the 264 field" do
      expect(@record['264']['a']).to eq('Dublin, OH')
      expect(@record['264']['b']).to eq('OCLC Press')
      expect(@record['264']['c']).to eq('2014')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
      field_tag = '264'
      field_array = Array.new
      subfield_hash = Hash.new
      subfield_hash['a'] = ''
      subfield_hash['b'] = 'OCLC Press'
      subfield_hash['c'] = '2014'
      field_hash = helpers.create_field_hash('b', ' ', '1', subfield_hash)
      field_array.push(field_hash)
      helpers.update_field(@record, field_tag, field_array)
      expect(@record['264']['a']).to be_nil
      expect(@record['264']['b']).to eq('OCLC Press')
      expect(@record['264']['c']).to eq('2014')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
    end

    it "should remove the publication date but not the 264 field" do
      expect(@record['264']['a']).to eq('Dublin, OH')
      expect(@record['264']['b']).to eq('OCLC Press')
      expect(@record['264']['c']).to eq('2014')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
      field_tag = '264'
      field_array = Array.new
      subfield_hash = Hash.new
      subfield_hash['a'] = 'Dublin, OH'
      subfield_hash['b'] = 'OCLC Press'
      subfield_hash['c'] = ''
      field_hash = helpers.create_field_hash('a', ' ', '1', subfield_hash)
      field_array.push(field_hash)
      helpers.update_field(@record, field_tag, field_array)
      expect(@record['264']['a']).to eq('Dublin, OH')
      expect(@record['264']['b']).to eq('OCLC Press')
      expect(@record['264']['c']).to be_nil
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
    end

    it "should remove the place of publication, publication date, publisher name and the 264 field" do
      expect(@record['264']['a']).to eq('Dublin, OH')
      expect(@record['264']['b']).to eq('OCLC Press')
      expect(@record['264']['c']).to eq('2014')
      expect(@record['264'].indicator1).to eq(' ')
      expect(@record['264'].indicator2).to eq('1')
      field_tag = '264'
      field_array = Array.new
      subfield_hash = Hash.new
      subfield_hash['a'] = ''
      subfield_hash['b'] = ''
      subfield_hash['c'] = ''
      field_hash = helpers.create_field_hash('a', ' ', '1', subfield_hash)
      field_array.push(field_hash)
      helpers.update_field(@record, field_tag, field_array)
      expect(@record['264']).to be_nil
    end
  end

  context "when creating a new MARC record with Chinese vernacular script in the title" do

    before(:each) do
      @params = {
        :oclc_symbol => 'OCPSB',
        :language => 'chi',
        :country_of_publication => 'cau',
        :title => '北京',
        :author => ['Doe, John'],
        :author_field_0 => '100',
        :place_of_publication => 'San Mateo, CA',
        :publisher => 'OCLC Press',
        :extent => '',
        :subject => [],
        :publication_date => '',
        :isbn => []
      }
      @record = helpers.marc_record_from_params('',@params)
    end
    
    it "should have a 245 field with <> in subfield a" do
      expect(@record['245']['a']).to eq('<>')
    end
    it "should have a 245 field with 880-01 in subfield 6" do
      expect(@record['245']['6']).to eq('880-01')
    end
    it "should have 245 indicator values 1 and 0" do
      expect(@record['245'].indicator1).to eq('1')
      expect(@record['245'].indicator2).to eq('0')
    end
    it "should have a 880 field with vernacular script in subfield a" do
      expect(@record['880']['a']).to eq('北京')
    end
    it "should have a 880 field with 245-01/$1 in subfield 6" do
      expect(@record['880']['6']).to eq('245-01/$1')
    end
    it "should have 880 indicator values 1 and 0" do
      expect(@record['880'].indicator1).to eq('1')
      expect(@record['880'].indicator2).to eq('0')
    end
    it "should have an 066 field with $1 in subfield c" do
      expect(@record['066']['c']).to eq('$1')
    end
  end
  
  context "when creating a new MARC record with Japanese (Katakana) vernacular script in the title" do

    before(:each) do
      @params = {
        :oclc_symbol => 'OCPSB',
        :language => 'jpn',
        :country_of_publication => 'cau',
        :title => 'ミンダナオーパプア',
        :author => ['Doe, John'],
        :author_field_0 => '100',
        :place_of_publication => 'San Mateo, CA',
        :publisher => 'OCLC Press',
        :extent => '',
        :subject => [],
        :publication_date => '',
        :isbn => []
      }
      @record = helpers.marc_record_from_params('',@params)
    end
    
    it "should have a 245 field with <> in subfield a" do
      expect(@record['245']['a']).to eq('<>')
    end
    it "should have a 245 field with 880-01 in subfield 6" do
      expect(@record['245']['6']).to eq('880-01')
    end
    it "should have 245 indicator values 1 and 0" do
      expect(@record['245'].indicator1).to eq('1')
      expect(@record['245'].indicator2).to eq('0')
    end
    it "should have a 880 field with vernacular script in subfield a" do
      expect(@record['880']['a']).to eq('ミンダナオーパプア')
    end
    it "should have a 880 field with 245-01/$1 in subfield 6" do
      expect(@record['880']['6']).to eq('245-01/$1')
    end
    it "should have 880 indicator values 1 and 0" do
      expect(@record['880'].indicator1).to eq('1')
      expect(@record['880'].indicator2).to eq('0')
    end
    it "should have an 066 field with $1 in subfield c" do
      expect(@record['066']['c']).to eq('$1')
    end
  end
  
  context "when creating a new MARC record with Korean (Hangul) vernacular script in the title" do

    before(:each) do
      @params = {
        :oclc_symbol => 'OCPSB',
        :language => 'kor',
        :country_of_publication => 'cau',
        :title => '회 선미술상 수상작가 김범 작품전',
        :author => ['Doe, John'],
        :author_field_0 => '100',
        :place_of_publication => 'San Mateo, CA',
        :publisher => 'OCLC Press',
        :extent => '',
        :subject => [],
        :publication_date => '',
        :isbn => []
      }
      @record = helpers.marc_record_from_params('',@params)
    end
    
    it "should have a 245 field with <> in subfield a" do
      expect(@record['245']['a']).to eq('<>')
    end
    it "should have a 245 field with 880-01 in subfield 6" do
      expect(@record['245']['6']).to eq('880-01')
    end
    it "should have 245 indicator values 1 and 0" do
      expect(@record['245'].indicator1).to eq('1')
      expect(@record['245'].indicator2).to eq('0')
    end
    it "should have a 880 field with vernacular script in subfield a" do
      expect(@record['880']['a']).to eq('회 선미술상 수상작가 김범 작품전')
    end
    it "should have a 880 field with 245-01/$1 in subfield 6" do
      expect(@record['880']['6']).to eq('245-01/$1')
    end
    it "should have 880 indicator values 1 and 0" do
      expect(@record['880'].indicator1).to eq('1')
      expect(@record['880'].indicator2).to eq('0')
    end
    it "should have an 066 field with $1 in subfield c" do
      expect(@record['066']['c']).to eq('$1')
    end
  end
  
  context "when creating a new MARC record with Basic Hebrew vernacular script in the title" do

    before(:each) do
      @params = {
        :oclc_symbol => 'OCPSB',
        :language => 'heb',
        :country_of_publication => 'cau',
        :title => '‏תל אביב.',
        :author => ['Doe, John'],
        :author_field_0 => '100',
        :place_of_publication => 'San Mateo, CA',
        :publisher => 'OCLC Press',
        :extent => '',
        :subject => [],
        :publication_date => '',
        :isbn => []
      }
      @record = helpers.marc_record_from_params('',@params)
    end
    
    it "should have a 245 field with <> in subfield a" do
      expect(@record['245']['a']).to eq('<>')
    end
    it "should have a 245 field with 880-01 in subfield 6" do
      expect(@record['245']['6']).to eq('880-01')
    end
    it "should have 245 indicator values 1 and 0" do
      expect(@record['245'].indicator1).to eq('1')
      expect(@record['245'].indicator2).to eq('0')
    end
    it "should have a 880 field with vernacular script in subfield a" do
      expect(@record['880']['a']).to eq('‏תל אביב.')
    end
    it "should have a 880 field with 245-01/(2 in subfield 6" do
      expect(@record['880']['6']).to eq('245-01/(2')
    end
    it "should have 880 indicator values 1 and 0" do
      expect(@record['880'].indicator1).to eq('1')
      expect(@record['880'].indicator2).to eq('0')
    end
    it "should have an 066 field with (2 in subfield c" do
      expect(@record['066']['c']).to eq('(2')
    end
  end

  context "when creating a new MARC record with Basic Arabic vernacular script in the title" do

    before(:each) do
      @params = {
        :oclc_symbol => 'OCPSB',
        :language => 'ara',
        :country_of_publication => 'cau',
        :title => 'كتاب التوحيد : الذي هو حق الله على العبيد',
        :author => ['Doe, John'],
        :author_field_0 => '100',
        :place_of_publication => 'San Mateo, CA',
        :publisher => 'OCLC Press',
        :extent => '',
        :subject => [],
        :publication_date => '',
        :isbn => []
      }
      @record = helpers.marc_record_from_params('',@params)
    end
    
    it "should have a 245 field with <> in subfield a" do
      expect(@record['245']['a']).to eq('<>')
    end
    it "should have a 245 field with 880-01 in subfield 6" do
      expect(@record['245']['6']).to eq('880-01')
    end
    it "should have 245 indicator values 1 and 0" do
      expect(@record['245'].indicator1).to eq('1')
      expect(@record['245'].indicator2).to eq('0')
    end
    it "should have a 880 field with vernacular script in subfield a" do
      expect(@record['880']['a']).to eq('كتاب التوحيد : الذي هو حق الله على العبيد')
    end
    it "should have a 880 field with 245-01/(3 in subfield 6" do
      expect(@record['880']['6']).to eq('245-01/(3')
    end
    it "should have 880 indicator values 1 and 0" do
      expect(@record['880'].indicator1).to eq('1')
      expect(@record['880'].indicator2).to eq('0')
    end
    it "should have an 066 field with (3 in subfield c" do
      expect(@record['066']['c']).to eq('(3')
    end
  end
  
  context "when creating a new MARC record with Extended Arabic vernacular script in the title" do

    before(:each) do
      @params = {
        :oclc_symbol => 'OCPSB',
        :language => 'ara',
        :country_of_publication => 'cau',
        :title => 'پانى كى بوچهار',
        :author => ['Doe, John'],
        :author_field_0 => '100',
        :place_of_publication => 'San Mateo, CA',
        :publisher => 'OCLC Press',
        :extent => '',
        :subject => [],
        :publication_date => '',
        :isbn => []
      }
      @record = helpers.marc_record_from_params('',@params)
    end
    
    it "should have a 245 field with <> in subfield a" do
      expect(@record['245']['a']).to eq('<>')
    end
    it "should have a 245 field with 880-01 in subfield 6" do
      expect(@record['245']['6']).to eq('880-01')
    end
    it "should have 245 indicator values 1 and 0" do
      expect(@record['245'].indicator1).to eq('1')
      expect(@record['245'].indicator2).to eq('0')
    end
    it "should have a 880 field with vernacular script in subfield a" do
      expect(@record['880']['a']).to eq('پانى كى بوچهار')
    end
    it "should have a 880 field with 245-01/(4 in subfield 6" do
      expect(@record['880']['6']).to eq('245-01/(4')
    end
    it "should have 880 indicator values 1 and 0" do
      expect(@record['880'].indicator1).to eq('1')
      expect(@record['880'].indicator2).to eq('0')
    end
    it "should have an 066 field with (4 in subfield c" do
      expect(@record['066']['c']).to eq('(4')
    end
  end
  
  context "when creating a new MARC record with Basic Cyrillic vernacular script in the title" do

    before(:each) do
      @params = {
        :oclc_symbol => 'OCPSB',
        :language => 'rus',
        :country_of_publication => 'cau',
        :title => 'Ленин',
        :author => ['Doe, John'],
        :author_field_0 => '100',
        :place_of_publication => 'San Mateo, CA',
        :publisher => 'OCLC Press',
        :extent => '',
        :subject => [],
        :publication_date => '',
        :isbn => []
      }
      @record = helpers.marc_record_from_params('',@params)
    end
    
    it "should have a 245 field with <> in subfield a" do
      expect(@record['245']['a']).to eq('<>')
    end
    it "should have a 245 field with 880-01 in subfield 6" do
      expect(@record['245']['6']).to eq('880-01')
    end
    it "should have 245 indicator values 1 and 0" do
      expect(@record['245'].indicator1).to eq('1')
      expect(@record['245'].indicator2).to eq('0')
    end
    it "should have a 880 field with vernacular script in subfield a" do
      expect(@record['880']['a']).to eq('Ленин')
    end
    it "should have a 880 field with 245-01/(N in subfield 6" do
      expect(@record['880']['6']).to eq('245-01/(N')
    end
    it "should have 880 indicator values 1 and 0" do
      expect(@record['880'].indicator1).to eq('1')
      expect(@record['880'].indicator2).to eq('0')
    end
    it "should have an 066 field with (N in subfield c" do
      expect(@record['066']['c']).to eq('(N')
    end
  end

  context "when creating a new MARC record with Extended Cyrillic vernacular script in the title" do

    before(:each) do
      @params = {
        :oclc_symbol => 'OCPSB',
        :language => 'rus',
        :country_of_publication => 'cau',
        :title => 'ћ',
        :author => ['Doe, John'],
        :author_field_0 => '100',
        :place_of_publication => 'San Mateo, CA',
        :publisher => 'OCLC Press',
        :extent => '',
        :subject => [],
        :publication_date => '',
        :isbn => []
      }
      @record = helpers.marc_record_from_params('',@params)
    end
    
    it "should have a 245 field with <> in subfield a" do
      expect(@record['245']['a']).to eq('<>')
    end
    it "should have a 245 field with 880-01 in subfield 6" do
      expect(@record['245']['6']).to eq('880-01')
    end
    it "should have 245 indicator values 1 and 0" do
      expect(@record['245'].indicator1).to eq('1')
      expect(@record['245'].indicator2).to eq('0')
    end
    it "should have a 880 field with vernacular script in subfield a" do
      expect(@record['880']['a']).to eq('ћ')
    end
    it "should have a 880 field with 245-01/(Q in subfield 6" do
      expect(@record['880']['6']).to eq('245-01/(Q')
    end
    it "should have 880 indicator values 1 and 0" do
      expect(@record['880'].indicator1).to eq('1')
      expect(@record['880'].indicator2).to eq('0')
    end
    it "should have an 066 field with (Q in subfield c" do
      expect(@record['066']['c']).to eq("(Q")
    end
  end
  
  context "when creating a new MARC record with Extended Greek vernacular script in the title" do

    before(:each) do
      @params = {
        :oclc_symbol => 'OCPSB',
        :language => 'gre',
        :country_of_publication => 'cau',
        :title => 'Ελλάδα',
        :author => ['Doe, John'],
        :author_field_0 => '100',
        :place_of_publication => 'San Mateo, CA',
        :publisher => 'OCLC Press',
        :extent => '',
        :subject => [],
        :publication_date => '',
        :isbn => []
      }
      @record = helpers.marc_record_from_params('',@params)
    end
    
    it "should have a 245 field with <> in subfield a" do
      expect(@record['245']['a']).to eq('<>')
    end
    it "should have a 245 field with 880-01 in subfield 6" do
      expect(@record['245']['6']).to eq('880-01')
    end
    it "should have 245 indicator values 1 and 0" do
      expect(@record['245'].indicator1).to eq('1')
      expect(@record['245'].indicator2).to eq('0')
    end
    it "should have a 880 field with vernacular script in subfield a" do
      expect(@record['880']['a']).to eq('Ελλάδα')
    end
    it "should have a 880 field with 245-01/(S in subfield 6" do
      expect(@record['880']['6']).to eq('245-01/(S')
    end
    it "should have 880 indicator values 1 and 0" do
      expect(@record['880'].indicator1).to eq('1')
      expect(@record['880'].indicator2).to eq('0')
    end
    it "should have an 066 field with (S in subfield c" do
      expect(@record['066']['c']).to eq('(S')
    end
  end
  
  context "when creating a new MARC record with Armenian vernacular script in the title" do

    before(:each) do
      @params = {
        :oclc_symbol => 'OCPSB',
        :language => 'arm',
        :country_of_publication => 'cau',
        :title => 'Լրաբեր հասարակական գիտությունների',
        :author => ['Doe, John'],
        :author_field_0 => '100',
        :place_of_publication => 'San Mateo, CA',
        :publisher => 'OCLC Press',
        :extent => '',
        :subject => [],
        :publication_date => '',
        :isbn => []
      }
      @record = helpers.marc_record_from_params('',@params)
    end
    
    it "should have a 245 field with <> in subfield a" do
      expect(@record['245']['a']).to eq('<>')
    end
    it "should have a 245 field with 880-01 in subfield 6" do
      expect(@record['245']['6']).to eq('880-01')
    end
    it "should have 245 indicator values 1 and 0" do
      expect(@record['245'].indicator1).to eq('1')
      expect(@record['245'].indicator2).to eq('0')
    end
    it "should have a 880 field with vernacular script in subfield a" do
      expect(@record['880']['a']).to eq('Լրաբեր հասարակական գիտությունների')
    end
    it "should have a 880 field with 245-01/Armn in subfield 6" do
      expect(@record['880']['6']).to eq('245-01/Armn')
    end
    it "should have 880 indicator values 1 and 0" do
      expect(@record['880'].indicator1).to eq('1')
      expect(@record['880'].indicator2).to eq('0')
    end
    it "should have an 066 field with Armn in subfield c" do
      expect(@record['066']['c']).to eq('Armn')
    end
  end
  
  context "when creating a new MARC record with Bengali vernacular script in the title" do

    before(:each) do
      @params = {
        :oclc_symbol => 'OCPSB',
        :language => 'ben',
        :country_of_publication => 'cau',
        :title => 'মাটির ময়না',
        :author => ['Doe, John'],
        :author_field_0 => '100',
        :place_of_publication => 'San Mateo, CA',
        :publisher => 'OCLC Press',
        :extent => '',
        :subject => [],
        :publication_date => '',
        :isbn => []
      }
      @record = helpers.marc_record_from_params('',@params)
    end
    
    it "should have a 245 field with <> in subfield a" do
      expect(@record['245']['a']).to eq('<>')
    end
    it "should have a 245 field with 880-01 in subfield 6" do
      expect(@record['245']['6']).to eq('880-01')
    end
    it "should have 245 indicator values 1 and 0" do
      expect(@record['245'].indicator1).to eq('1')
      expect(@record['245'].indicator2).to eq('0')
    end
    it "should have a 880 field with vernacular script in subfield a" do
      expect(@record['880']['a']).to eq('মাটির ময়না')
    end
    it "should have a 880 field with 245-01/Beng in subfield 6" do
      expect(@record['880']['6']).to eq('245-01/Beng')
    end
    it "should have 880 indicator values 1 and 0" do
      expect(@record['880'].indicator1).to eq('1')
      expect(@record['880'].indicator2).to eq('0')
    end
    it "should have an 066 field with Beng in subfield c" do
      expect(@record['066']['c']).to eq('Beng')
    end
  end
  
  context "when creating a new MARC record with Devanagari vernacular script in the title" do

    before(:each) do
      @params = {
        :oclc_symbol => 'OCPSB',
        :language => 'san',
        :country_of_publication => 'cau',
        :title => 'वाटर',
        :author => ['Doe, John'],
        :author_field_0 => '100',
        :place_of_publication => 'San Mateo, CA',
        :publisher => 'OCLC Press',
        :extent => '',
        :subject => [],
        :publication_date => '',
        :isbn => []
      }
      @record = helpers.marc_record_from_params('',@params)
    end
    
    it "should have a 245 field with <> in subfield a" do
      expect(@record['245']['a']).to eq('<>')
    end
    it "should have a 245 field with 880-01 in subfield 6" do
      expect(@record['245']['6']).to eq('880-01')
    end
    it "should have 245 indicator values 1 and 0" do
      expect(@record['245'].indicator1).to eq('1')
      expect(@record['245'].indicator2).to eq('0')
    end
    it "should have a 880 field with vernacular script in subfield a" do
      expect(@record['880']['a']).to eq('वाटर')
    end
    it "should have a 880 field with 245-01/Deva in subfield 6" do
      expect(@record['880']['6']).to eq('245-01/Deva')
    end
    it "should have 880 indicator values 1 and 0" do
      expect(@record['880'].indicator1).to eq('1')
      expect(@record['880'].indicator2).to eq('0')
    end
    it "should have an 066 field with Deva in subfield c" do
      expect(@record['066']['c']).to eq('Deva')
    end
  end
  
  context "when creating a new MARC record with Ethiopic vernacular script in the title" do

    before(:each) do
      @params = {
        :oclc_symbol => 'OCPSB',
        :language => 'eth',
        :country_of_publication => 'cau',
        :title => 'የኢትዮጵያ ኦርቶዶክስ ተዋሕዶ ቤተ ክርስቲያን',
        :author => ['Doe, John'],
        :author_field_0 => '100',
        :place_of_publication => 'San Mateo, CA',
        :publisher => 'OCLC Press',
        :extent => '',
        :subject => [],
        :publication_date => '',
        :isbn => []
      }
      @record = helpers.marc_record_from_params('',@params)
    end
    
    it "should have a 245 field with <> in subfield a" do
      expect(@record['245']['a']).to eq('<>')
    end
    it "should have a 245 field with 880-01 in subfield 6" do
      expect(@record['245']['6']).to eq('880-01')
    end
    it "should have 245 indicator values 1 and 0" do
      expect(@record['245'].indicator1).to eq('1')
      expect(@record['245'].indicator2).to eq('0')
    end
    it "should have a 880 field with vernacular script in subfield a" do
      expect(@record['880']['a']).to eq('የኢትዮጵያ ኦርቶዶክስ ተዋሕዶ ቤተ ክርስቲያን')
    end
    it "should have a 880 field with 245-01/Ethi in subfield 6" do
      expect(@record['880']['6']).to eq('245-01/Ethi')
    end
    it "should have 880 indicator values 1 and 0" do
      expect(@record['880'].indicator1).to eq('1')
      expect(@record['880'].indicator2).to eq('0')
    end
    it "should have an 066 field with Ethi in subfield c" do
      expect(@record['066']['c']).to eq('Ethi')
    end
  end
  
  context "when creating a new MARC record with Syriac vernacular script in the title" do

    before(:each) do
      @params = {
        :oclc_symbol => 'OCPSB',
        :language => 'syr',
        :country_of_publication => 'cau',
        :title => 'ܓܪܫܘ',
        :author => ['Doe, John'],
        :author_field_0 => '100',
        :place_of_publication => 'San Mateo, CA',
        :publisher => 'OCLC Press',
        :extent => '',
        :subject => [],
        :publication_date => '',
        :isbn => []
      }
      @record = helpers.marc_record_from_params('',@params)
    end
    
    it "should have a 245 field with <> in subfield a" do
      expect(@record['245']['a']).to eq('<>')
    end
    it "should have a 245 field with 880-01 in subfield 6" do
      expect(@record['245']['6']).to eq('880-01')
    end
    it "should have 245 indicator values 1 and 0" do
      expect(@record['245'].indicator1).to eq('1')
      expect(@record['245'].indicator2).to eq('0')
    end
    it "should have a 880 field with vernacular script in subfield a" do
      expect(@record['880']['a']).to eq('ܓܪܫܘ')
    end
    it "should have a 880 field with 245-01/Syrc in subfield 6" do
      expect(@record['880']['6']).to eq('245-01/Syrc')
    end
    it "should have 880 indicator values 1 and 0" do
      expect(@record['880'].indicator1).to eq('1')
      expect(@record['880'].indicator2).to eq('0')
    end
    it "should have an 066 field with Syrc in subfield c" do
      expect(@record['066']['c']).to eq('Syrc')
    end
  end
  
  context "when creating a new MARC record with Tamil vernacular script in the title" do

    before(:each) do
      @params = {
        :oclc_symbol => 'OCPSB',
        :language => 'tam',
        :country_of_publication => 'cau',
        :title => 'எனது அப்பா பெரிய உருவம் கௌண்டவர்',
        :author => ['Doe, John'],
        :author_field_0 => '100',
        :place_of_publication => 'San Mateo, CA',
        :publisher => 'OCLC Press',
        :extent => '',
        :subject => [],
        :publication_date => '',
        :isbn => []
      }
      @record = helpers.marc_record_from_params('',@params)
    end
    
    it "should have a 245 field with <> in subfield a" do
      expect(@record['245']['a']).to eq('<>')
    end
    it "should have a 245 field with 880-01 in subfield 6" do
      expect(@record['245']['6']).to eq('880-01')
    end
    it "should have 245 indicator values 1 and 0" do
      expect(@record['245'].indicator1).to eq('1')
      expect(@record['245'].indicator2).to eq('0')
    end
    it "should have a 880 field with vernacular script in subfield a" do
      expect(@record['880']['a']).to eq('எனது அப்பா பெரிய உருவம் கௌண்டவர்')
    end
    it "should have a 880 field with 245-01/Taml in subfield 6" do
      expect(@record['880']['6']).to eq('245-01/Taml')
    end
    it "should have 880 indicator values 1 and 0" do
      expect(@record['880'].indicator1).to eq('1')
      expect(@record['880'].indicator2).to eq('0')
    end
    it "should have an 066 field with Taml in subfield c" do
      expect(@record['066']['c']).to eq('Taml')
    end
  end
  
  context "when creating a new MARC record with Thai vernacular script in the title" do

    before(:each) do
      @params = {
        :oclc_symbol => 'OCPSB',
        :language => 'tha',
        :country_of_publication => 'ta ',
        :title => 'ช ช้าง กับ ฅ ฅน',
        :author => ['Doe, John'],
        :author_field_0 => '100',
        :place_of_publication => 'San Mateo, CA',
        :publisher => 'OCLC Press',
        :extent => '',
        :subject => [],
        :publication_date => '',
        :isbn => []
      }
      @record = helpers.marc_record_from_params('',@params)
    end
    
    it "should have a 245 field with <> in subfield a" do
      expect(@record['245']['a']).to eq('<>')
    end
    it "should have a 245 field with 880-01 in subfield 6" do
      expect(@record['245']['6']).to eq('880-01')
    end
    it "should have 245 indicator values 1 and 0" do
      expect(@record['245'].indicator1).to eq('1')
      expect(@record['245'].indicator2).to eq('0')
    end
    it "should have a 880 field with vernacular script in subfield a" do
      expect(@record['880']['a']).to eq('ช ช้าง กับ ฅ ฅน')
    end
    it "should have a 880 field with 245-01/Thai in subfield 6" do
      expect(@record['880']['6']).to eq('245-01/Thai')
    end
    it "should have 880 indicator values 1 and 0" do
      expect(@record['880'].indicator1).to eq('1')
      expect(@record['880'].indicator2).to eq('0')
    end
    it "should have an 066 field with Thai in subfield c" do
      expect(@record['066']['c']).to eq('Thai')
    end
  end
  
  context "when displaying a MARC record created by my institution" do
  
    before(:each) do
      raw_marc = StringIO.new( mock_file_contents("ocn883876185.marcxml") )
      @record = MARC::XMLReader.new(raw_marc).first
    end
    
    it "should have my OCLC symbol in 040 subfield a" do
      expect(helpers.belongs_to_current_user?(@record, 'OCPSB')).to be true
    end
    
  end
  
  context "when displaying a MARC record created by my institution" do
  
    before(:each) do
      raw_marc = StringIO.new( mock_file_contents("ocn883876185.marcxml") )
      @record = MARC::XMLReader.new(raw_marc).first
    end
    
    it "should have my OCLC symbol in 040 subfield a" do
      expect(helpers.belongs_to_current_user?(@record, 'OCPSB')).to be true
    end

  end # when displaying a MARC record created by my institution
  
  context "when displaying a MARC record created by another institution" do

    before(:each) do
      raw_marc = StringIO.new( mock_file_contents("ocn883880805.marcxml") )
      @record = MARC::XMLReader.new(raw_marc).first
    end
    
    it "should not have my OCLC symbol in 040 subfield a" do
      expect(helpers.belongs_to_current_user?(@record, 'OCPSB')).not_to be true
    end

  end # when displaying a MARC record created by my institution
  
end