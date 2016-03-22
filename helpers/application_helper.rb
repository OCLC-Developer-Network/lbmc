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

module ApplicationHelper

  def detect_unicode_block(str)
    matches = Array.new
    LBMC::LANGUAGES.each do |lang, lang_regex|
      matches << lang if str =~ lang_regex
    end
    puts ; puts matches ; puts
    matches
  end
  
  def detect_script(str)
    unicode_blocks = Array.new
    scripts = Array.new
    LBMC::LANGUAGES.each do |lang, lang_regex|
      unicode_blocks << lang if str =~ lang_regex
      xlang = lang if str =~ lang_regex
      unless scripts.include?(LBMC::SCRIPT_CODES[xlang]) || lang == "Arabic" || lang == "Cyrillic"
        if LBMC::NONMARC_LANGUAGES.include?(xlang)
          scripts << LBMC::SCRIPT_CODES[xlang]
        end
      end
    end
    if str
      str.split("").each do |char|
        if (char >= "\u{3000}" && char <= "\u{FAFF}") || (char >= "\u{FF00}" && char <= "\u{FFEF}")
          script_code = LBMC::SCRIPT_CODES["CJK"]
          unless scripts.include?(script_code)
            scripts << script_code
          end
        elsif unicode_blocks.include?("Arabic")
          if char >= "\u{0600}" && char <= "\u{0671}" 
            script_code = LBMC::SCRIPT_CODES["ARABIC_BAS"]
            unless scripts.include?(script_code)
              scripts << script_code
            end
          elsif char >= "\u{0672}" && char <= "\u{06FF}"
            script_code = LBMC::SCRIPT_CODES["ARABIC_EXT"]
            unless scripts.include?(script_code)
              scripts << script_code
            end
          end
        elsif (char >= "\u{0400}" && char <= "\u{04FF}")
          # puts char.ord.to_s(16)
          if char >= "\u{0410}" && char <= "\u{0450}"
            script_code = LBMC::SCRIPT_CODES["CYRILLIC_BAS"]
            unless scripts.include?(script_code)
              scripts << script_code
            end
          else 
            script_code = LBMC::SCRIPT_CODES["CYRILLIC_EXT"]
            unless scripts.include?(script_code)
              scripts << script_code
            end
          end
        # elsif (char >= "\u{0460}" && char <= "\u{052F}") || (char >= "\u{0500}" && char <= "\u{052F}") || (char >= "\u{2DE0}" && char <= "\u{2DFF}") || (char >= "\u{A640}" && char <= "\u{A69F}")
        elsif char == "\u{0400}" || (char >= "\u{0460}" && char <= "\u{0461}") || (char >= "\u{0464}" && char <= "\u{0469}") || (char >= "\u{046C}" && char <= "\u{0471}") || (char >= "\u{0476}" && char <= "\u{048F}") || (char >= "\u{0492}" && char <= "\u{04FF}")
          script_code = LBMC::SCRIPT_CODES["CYRILLIC_NONMARC"]
          unless scripts.include?(script_code)
            scripts << script_code
          end
        #elsif (char >= "\u{1200}" && char <= "\u{1399}") || (char >= "\u{2d80}" && char <= "\u{2ddf}") || (char >= "\u{ab00}" && char <= "\u{ab2f}")
          #script_code = LBMC::SCRIPT_CODES["ETHI"]
          #unless scripts.include?(script_code)
            #scripts << script_code
          #
        end
      end        
    end
    scripts
  end
  
  def create_book_record
    record = MARC::Record.new
    record.leader[0,5] = '00000'
    record.leader[5] = 'n'
    record.leader[6] = 'a'
    record.leader[7] = 'm'
    record.leader[17] = '3'
    record.leader[18] = 'c'
    record
  end
  
  def book_fixed_length_data()
    fde = MARC::ControlField.new('008')
    fde.value = ''.rjust(40, ' ')
    now = Time.now
    year = now.year.to_s[2,2]
    month = now.month.to_s.rjust(2, '0')
    day = now.day.to_s.rjust(2, '0')
    fde.value[0,6] = "#{year}#{month}#{day}"
    fde.value[6,1] = 's'
    fde.value[7,4] = now.year.to_s
    fde.value[11,4] = '    '
    fde.value[15,3] = 'xx '
    fde.value[18,1] = ' '
    fde.value[19,1] = ' '
    fde.value[22,1] = ' '
    fde.value[23,1] = ' '
    fde.value[24,1] = ' '
    fde.value[28,1] = ' '
    fde.value[29,1] = '0'
    fde.value[30,1] = '0'
    fde.value[31,1] = '0'
    fde.value[33,1] = 'u'
    fde.value[34,1] = ' '
    fde.value[35,3] = '   '
    fde.value[38,1] = ' '
    fde.value[39,1] = 'd'
    fde
  end
  
  def publication_date_is_positive_number?(publication_date)
    /^-?[1-9]\d*$/ =~ publication_date
  end
  
  def marc_record_from_params(record, params)
  
    # puts ; puts params.inspect ; puts
  
    marc_record = record
    
    # If the record value wasn't a MARC record ...create an instance of one, initialize 008 string and add an 040 for the OCLC symbol
    unless record.kind_of?(MARC::Record)
    
      # Create an instance of a MARC record
      marc_record = create_book_record
      
      # Initialize 008
      marc_record << book_fixed_length_data()
      
      # Add the client OCLC symbol to the 040, maintaining conventional subfield order a, b, e, c, [d]
      field_tag = "040"
      field_array = Array.new
      subfield_hash = Hash.new
      subfield_hash["a"] = params[:oclc_symbol]
      subfield_hash["b"] = 'eng'
      subfield_hash["e"] = 'rda'
      subfield_hash["c"] = params[:oclc_symbol]
      field_hash = create_field_hash('a', ' ', ' ', subfield_hash)
      field_array.push(field_hash)
      update_field(marc_record, field_tag, field_array)
      
      # Add the application note
      field_tag = "500"
      field_array = Array.new
      subfield_hash = Hash.new
      subfield_hash["a"] = LBMC::SOURCE_NOTE
      field_hash = create_field_hash('a', ' ', ' ', subfield_hash)
      field_array.push(field_hash)
      update_field(marc_record, field_tag, field_array)
      
    end
  
    # CONTROL FIELDS
    
    unless params[:language].nil?
      language_code = '%-3.3s' % params[:language]
      update_control_field_value(marc_record, '008', 35, language_code)
    end
    unless params[:country_of_publication].nil?
      country_code = '%-3.3s' % params[:country_of_publication]
      update_control_field_value(marc_record, '008', 15, country_code)
    end
    pd = params[:publication_date]
    unless params[:pd1].nil?
      pd = params[:pd1]
    end
    unless pd.nil?
      if publication_date_is_positive_number?(pd)
        if params[:calendar_select].nil? || params[:calendar_select] == "gregorian"
          pd = pd.rjust(4, '0')
        else
          pd = pd[0..2]+"u"
        end
        update_control_field_value(marc_record, '008', 7, pd)
      end
    end
    
    # NON-LATIN SETUP
    v880_fields = Array.new
    v066_subfields = Array.new
    
    # AUTHOR MAIN ENTRY
    
    # Delete any existing author main entries
    delete_field(marc_record, ['100','110'])
    
    # Set the default first indicator for the title
    title_indicator_1 = '0'
    
    # If the author array has at least one value ...
    unless params[:author].empty?
      ainc = 0
      # For each author
      params[:author].each do |author|
        # Get the first author that does not include non-Latin characters and treat it as the author main entry
        unless author.to_s == ""
          author_languages = detect_script(author)
          if author_languages.length == 0
            param_text = 'author_field_'+ainc.to_s
            param_sym = param_text.to_sym
            field_tag = params[param_sym]
            field_indicator_1 = '1'
            if field_tag == "110"
              field_indicator_1 = '2'
            end
            field_array = Array.new
            subfield_hash = Hash.new
            subfield_hash["a"] = author
            field_hash = create_field_hash('a', field_indicator_1, ' ', subfield_hash)
            field_array.push(field_hash)
            update_field(marc_record, field_tag, field_array)
            # reset the title first indicator indicating the presence of a main entry
            title_indicator_1 = '1'
            # remove this author from the params[author] array
            params[:author].delete_at(ainc)
            # Quit looping through authors
            break
          end 
        end
        ainc += 1
      end
    end

    # AUTHOR ADDED ENTRIES
    
    # Delete any existing 700 and 710 entries and any 066s or 880s
    delete_field(marc_record, ['700','710','066','880'])
    
    # If there entries left in the author parameter array ..
    if params[:author].length > 0
      aeinc = 0
      v700s = Array.new
      v710s = Array.new
      params[:author].each do |a|
        unless a.empty?
          af = "author_field_"+aeinc.to_s
          if params[af] == "100"
            v700s.push(a)
          else
            v710s.push(a)
          end
          aeinc += 1
        end
      end
      if v700s.length > 0
        field_tag = "700"
        field_array = Array.new
        v700s.each do |v700|
          subfield_hash = Hash.new
          subfield_hash["a"] = v700
          author_languages = detect_script(v700)
          if author_languages.length > 0
            v066_subfields.concat author_languages
            # if an author main entry hasn't already been set, swap the field tag
            if title_indicator_1 == '0'
              field_tag = "100"
              title_indicator_1 = '1'
            else 
              field_tag = "700"
            end
            subfield_hash["6"] = field_tag+'-00/'+author_languages[0]
            field_hash = create_field_hash('6', '1', ' ', subfield_hash)
            v880_fields.push(field_hash)
          else
            field_hash = create_field_hash('a', '1', ' ', subfield_hash)
            field_array.push(field_hash)
          end
        end
        if field_array.length > 0
          update_field(marc_record, field_tag, field_array)
        end
      end
      if v710s.length > 0
        field_tag = "710"
        field_array = Array.new
        v710s.each do |v710|
          subfield_hash = Hash.new
          subfield_hash["a"] = v710
          author_languages = detect_script(v710)
          if author_languages.length > 0
            v066_subfields.concat author_languages
            # if an author main entry hasn't already been set, swap the field tag
            if title_indicator_1 == '0'
              field_tag = "110"
              title_indicator_1 = '1'
            else 
              field_tag = "710"
            end
            subfield_hash["6"] = field_tag+'-00/'+author_languages[0]
            field_hash = create_field_hash('6', '2', ' ', subfield_hash)
            v880_fields.push(field_hash)
          else
            field_hash = create_field_hash('a', '2', ' ', subfield_hash)
            field_array.push(field_hash)
          end
        end
        if field_array.length > 0
          update_field(marc_record, field_tag, field_array)
        end
      end
    end
  
    # TITLE

    # Remove 245's
    delete_field(marc_record, ['245'])
    
    # Detect languages of the title string
    title_languages = detect_script(params[:title])
    
    if title_languages.length > 0
    
      # the title is in one or more non-Latin scripts
      
      # add language codes to the 066 subfield value array
      v066_subfields.concat title_languages

      # add a 245 with placeholder value and a pointer to an 880
      field_tag = "245"
      field_array = Array.new
      subfield_hash = Hash.new
      subfield_hash["6"] =  '880-01'
      subfield_hash["a"] =  '<>'
      field_hash = create_field_hash('6', title_indicator_1, '0', subfield_hash)
      field_array.push(field_hash)
      update_field(marc_record, field_tag, field_array)
      
      # add an 880 with field tag, indicators, and subfields to the v880s array
      field_hash = Hash.new
      subfield_hash = Hash.new
      subfield_hash["a"] =  params[:title]
      subfield_hash["6"] =  '245-01/'+title_languages[0]
      field_hash = create_field_hash('6', title_indicator_1, '0', subfield_hash)
      v880_fields.push(field_hash)
      
    else
    
      # title is in Latin script only
      
      field_tag = "245"
      field_array = Array.new
      subfield_hash = Hash.new
      subfield_hash["a"] =  params[:title]
      field_hash = create_field_hash('a', title_indicator_1, '0', subfield_hash)
      field_array.push(field_hash)
      update_field(marc_record, field_tag, field_array)
      
    end

    # PUBLICATION DATA
    
    field_tag = "264"
    field_array = Array.new
    subfield_hash = Hash.new
    unless params[:place_of_publication].to_s == ''
      subfield_hash["a"] = params[:place_of_publication]
    end
    unless params[:publisher].to_s == ''
      subfield_hash["b"] = params[:publisher]
    end
    unless params[:publication_date].to_s == ''
      subfield_hash["c"] = params[:publication_date]
    end
    field_hash = create_field_hash('', ' ', '1', subfield_hash)
    place_of_publication_languages = detect_script(params[:place_of_publication])
    publisher_languages = detect_script(params[:publisher])
    publication_date_languages = detect_script(params[:publication_date])
    if place_of_publication_languages.length > 0 || publisher_languages.length > 0 || publication_date_languages.length > 0
      publisher_v066 = Array.new
      publisher_v066.concat place_of_publication_languages
      publisher_v066.concat publisher_languages
      publisher_v066.concat publication_date_languages
      # add to 880s
      subfield_hash["6"] = field_tag+'-00/'+publisher_v066[0]
      field_hash = create_field_hash('6', ' ', '1', subfield_hash)
      v880_fields.push(field_hash)
    else
      unless subfield_hash.empty?
        field_hash = create_field_hash('', ' ', '1', subfield_hash)
        field_array.push(field_hash)
      end
    end
    update_field(marc_record, field_tag, field_array)
    
    # EXTENT
    
    if params[:extent].length > 0
      field_tag = "300"
      field_array = Array.new
      subfield_hash = Hash.new
      subfield_hash["a"] = params[:extent]
      extent_languages = detect_script(params[:extent])
      if extent_languages.length > 0
        # add to 880s
        subfield_hash["6"] = field_tag+'-00/'+extent_languages[0]
        field_hash = create_field_hash('6', ' ', ' ', subfield_hash)
        v880_fields.push(field_hash)
      else
        field_hash = create_field_hash('a', ' ', ' ', subfield_hash)
        field_array.push(field_hash)
      end
      update_field(marc_record, field_tag, field_array)
    end
    
    # RDA CONTENT, MEDIA, AND CARRIER TYPE
    
    field_tag = "336"
    field_array = Array.new
    subfield_hash = Hash.new
    subfield_hash["a"] = "text"
    subfield_hash["b"] = "txt"
    subfield_hash["2"] = "rdacontent"
    field_hash = create_field_hash('a', ' ', ' ', subfield_hash)
    field_array.push(field_hash)
    update_field(marc_record, field_tag, field_array)
    
    field_tag = "337"
    field_array = Array.new
    subfield_hash = Hash.new
    subfield_hash["a"] = "unmediated"
    subfield_hash["b"] = "n"
    subfield_hash["2"] = "rdamedia"
    field_hash = create_field_hash('a', ' ', ' ', subfield_hash)
    field_array.push(field_hash)
    update_field(marc_record, field_tag, field_array)
    
    field_tag = "338"
    field_array = Array.new
    subfield_hash = Hash.new
    subfield_hash["a"] = "volume"
    subfield_hash["b"] = "nc"
    subfield_hash["2"] = "rdacarrier"
    field_hash = create_field_hash('a', ' ', ' ', subfield_hash)
    field_array.push(field_hash)
    update_field(marc_record, field_tag, field_array)

    # SUBJECTS
    
    # Define subject tags we care about
    subject_tags = Array.new(['600','610','611','630','648','650','651','653','655'])
    
    # Remove any existing subjects
    delete_field(marc_record, subject_tags)
    
    # Create empty arrays to hold different types of subjects
    subject_hash = Hash.new
    subject_tags.each do |st|
      subject_hash[st.to_s] = Array.new
    end
    
    # Step through the subjects parameter array and add its value to a subject_hash based on its corresponding subjects_type array value
    if params[:subject].kind_of?(Array)
      sinc = 0
      params[:subject].each do |s|
        unless s.empty?
          field_tag = '653'
          unless params[:subject_type][sinc].nil?
            field_tag = params[:subject_type][sinc]
          end
          subfield_hash = Hash.new
          if params[:subject_raw][sinc].include?("$")
            subject_subfields = params[:subject_raw][sinc].split('$')
            subject_subfields.each do |ss|
              subfield_hash[ss[0]] = ss[1..ss.length]
            end
          else 
            subfield_hash['a'] = s
          end
          if field_tag != '653'
            subfield_hash['2'] = 'fast'
            subfield_hash['0'] = params[:subject_id][sinc]
          end
          field_indicator_1 = '0'
          field_indicator_2 = ' '
          unless params[:subject_indicator][sinc].nil? || field_tag == '653'
            field_indicator_1 = params[:subject_indicator][sinc]
            field_indicator_2 = '7'
          end
          if subfield_hash.has_key?("a")
            subject_languages = detect_script(s)
            if subject_languages.length > 0
              # add to 880s
              subfield_hash["6"] = field_tag+'-00/'+extent_languages[0]
              field_hash = create_field_hash('6', field_indicator_1, field_indicator_2, subfield_hash)
              v880_fields.push(field_hash)
            else
              field_hash = create_field_hash('a', field_indicator_1, field_indicator_2, subfield_hash)
              subject_hash[field_tag].push(field_hash)
              sinc += 1
            end
          end
        end
      end 
    end
    
    # Step through the subject hash by tag and add arrays of fields
    field_default_subfield = 'a'
    subject_hash.each do |key, value|
      if subject_hash[key].length > 0
        update_field(marc_record, key, subject_hash[key])
      end
    end
    
    # ADD 066 SUBFIELDS
    
    unless v066_subfields.empty?
      v066_subfields = v066_subfields.uniq
      field_tag = "066"
      field_array = Array.new
      subfield_hash = Hash.new
      subfield_hash['c'] = v066_subfields
      field_hash = create_field_hash('c', ' ', ' ', subfield_hash)
      field_array.push(field_hash)
      update_field(marc_record, field_tag, field_array)
    end
    
    # ADD 880 FIELDS
    
    unless v880_fields.empty?
      field_tag = "880"
      update_field(marc_record, field_tag, v880_fields)
    end
    
    # ISBN
    
    unless params[:isbn].to_s == ''
      field_tag = "020"
      field_array = Array.new
      params[:isbn].each do |isbn|
        isbn = isbn.tr("-","")
        unless isbn.empty?
          subfield_hash = Hash.new
          subfield_hash["a"] = isbn
          field_hash = create_field_hash('a', ' ', ' ', subfield_hash)
          field_array.push(field_hash)
        end
      end
      unless field_array.empty?
        update_field(marc_record, field_tag, field_array)
      end
    end
    
    # RETURN MARC RECORD
    
    # puts ; puts marc_record ; puts
    
    marc_record
    
  end
  
  def sort_subfields(marc_record, data_field_number)
    marc_record[data_field_number].subfields.sort_by! {|subfield| subfield.code}
  end
  
  def update_control_field_value(marc_record, control_field_number, starting_position, new_value)
    control_field = marc_record[control_field_number]
    control_field.value[starting_position,new_value.length] = new_value
  end

  def delete_field(marc_record, data_field_number_array)
    data_field_number_array.each do |data_field_number|
      data_field = marc_record[data_field_number]
      unless data_field.nil? # data_field is not nil ...
        # remove all occurrences of data_field from marc_record
        marc_record.each_by_tag(data_field_number) do |field| 
          marc_record.fields.delete(field)
        end
      end
    end
  end
  
  def create_field_hash(default_subfield, i1, i2, subfield_hash)
    field_hash = Hash.new
    field_hash["default_subfield"] = default_subfield
    field_hash["indicator"] = Hash.new
    field_hash["indicator"]["1"] = i1
    field_hash["indicator"]["2"] = i2
    field_hash["subfield"] = Hash.new
    subfield_hash.each do |key, value|
      unless value.to_s == ""
        field_hash["subfield"][key.to_s] = value
      end
    end
    field_hash
  end
  
  def update_field(marc_record, field_tag, field_array)

    # Create a new data field object for the given tag
    data_field = marc_record[field_tag]
    
    # Does at least one occurrence of the data_field currently exist?
    unless data_field.nil? # data_field is not nil ...
      # remove all occurrences of data_field from marc_record
      marc_record.each_by_tag(field_tag) do |field| 
        marc_record.fields.delete(field)
      end
    end
    
    # Only do more if the field_array is an array
    if field_array.kind_of?(Array)
    
      # For each item in the field_array
      field_array.each do |item|
      
        # Expect it to be a hash (containing the default subfield, indicators, and a hash of subfields)
        if item.kind_of?(Hash)
        
          unless item['subfield'].empty?
        
            # If the default subfield's hash value is an array, add each as repeating subfields in the same field
            if item['subfield'][item['default_subfield']].kind_of?(Array)
              inc = 0
              field = MARC::DataField.new(field_tag, item['indicator']['1'], item['indicator']['2'], MARC::Subfield.new(item['default_subfield'],item['subfield'][item['default_subfield']][0]))
              item['subfield'][item['default_subfield']].each do |i|
                if inc > 0
                  field.append(MARC::Subfield.new(item['default_subfield'],i))
                end
                inc += 1
              end
            
            # Otherwise, instantiate the field with the default subfield
            else
              field = MARC::DataField.new(field_tag, item['indicator']['1'], item['indicator']['2'], MARC::Subfield.new(item['default_subfield'],item['subfield'][item['default_subfield']]))
            end
            
            # add non-default subfields to the field
            item['subfield'].each do |key, value|
              if key != item['default_subfield']
                unless item['subfield'][key].nil?
                  field.append(MARC::Subfield.new(key,item['subfield'][key]))
                end
              end
            end 
            
            # add the field to the record
            marc_record << field
          
          end # unless item['subfield' is empty
          
        end # if item is a hash
        
      end # each field_array
      
    end # if field_array is an array
    
  end # update_field
  
  # Will respond true if the data field is not null and the given subfield code 
  # is the only subfield in the data field
  def field_is_deletable?(data_field, subfield_code)
    # Assume the given subfield_code matches the only subfield in the record.
    # If any others are encounterd, return false.
    data_field.subfields.reduce(true) do |deletable, subfield| 
      deletable = false if subfield.code != subfield_code
      deletable
    end
  end
  
  # Will respond true if the 040 subfield a in the MARC record matches the provided OCLC symbol
  def belongs_to_current_user?(marc_record, oclc_symbol)
    oclc_symbol == marc_record['040']['a']
  end
  
  # Escapes HTML
  def h(text)
    Rack::Utils.escape_html(text)
  end
  
end