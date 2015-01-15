# encoding: utf-8
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
  
  def marc_record_from_params(params)
    record = create_book_record
    record << book_fixed_length_data(params)
    
    # Language
    update_control_field_value(record, '008', 35, params[:language])
    
    # Country of publication
    update_control_field_value(record, '008', 15, params[:country_of_publication])
    
    # ISBN
    update_field_array(record, '020', 'a', ' ', ' ', params[:isbn])

    # OCLC Symbol
    update_field_value(record, '040', 'a', ' ', ' ', params[:oclc_symbol])
    update_field_value(record, '040', 'c', ' ', ' ', params[:oclc_symbol])
    update_field_value(record, '040', 'e', ' ', ' ', 'rda')
    
    # Author
    if params[:author].length > 0
      if params[:author_field_0] == "110"
        update_field_value(record, '110', 'a', '2', ' ', params[:author][0])
      else
        update_field_value(record, '100', 'a', '1', ' ', params[:author][0])
      end
    end
    
    # Added Entries
    if params[:author].length > 1
      aeinc = 0
      v700s = Array.new
      v710s = Array.new
      params[:author].each do |a|
        if aeinc > 0
          af = "author_field_"+aeinc.to_s
          if params[af] == "100"
            v700s.push(a)
          else
            v710s.push(a)
          end
        end
        aeinc += 1
      end
      if v700s.length > 0
        update_field_array(record, '700', 'a', '1', ' ', v700s)
      end
      if v710s.length > 0
        update_field_array(record, '710', 'a', '2', ' ', v710s)
      end
    end
    
    # Title
    
    # Set the first indicator value based on the presence or absence of a 1XX author
    title_indicator_1 = '0'
    if params[:author].length > 0
      if params[:author][0].strip.length > 0
        title_indicator_1 = '1'
      end
    end

    # Update the title 
    update_field_value(record, '245', 'a', title_indicator_1, '0', params[:title])
    
    # Detect language of the title string
    title_languages = detect_script(params[:title])

    # If title includes supported non-Latin languages
    if title_languages.length > 0
      title_languages.each do |l|
        update_field_value(record, '066', 'c', ' ', ' ', l)
      end
      update_field_value(record, '245', 'a', title_indicator_1, '0', '')
      update_field_value(record, '245', '6', title_indicator_1, '0', '880-01')
      update_field_value(record, '245', 'a', title_indicator_1, '0', '<>')
      update_field_value(record, '880', '6', title_indicator_1, '0', '245-01/'+title_languages[0])
      update_field_value(record, '880', 'a', title_indicator_1, '0', params[:title])
    end
    
    # Publication data
    update_field_value(record, '264', 'a', ' ', '1', params[:place_of_publication])
    update_field_value(record, '264', 'b', ' ', '1', params[:publisher])
    update_field_value(record, '264', 'c', ' ', '1', params[:publication_date])
    
    # Extent
    update_field_value(record, '300', 'a', ' ', ' ', params[:extent])
    
    # RDA Content, Media, and Carrier type
    update_field_value(record, '336', 'a', ' ', ' ', 'text')
    update_field_value(record, '336', 'b', ' ', ' ', 'txt')
    update_field_value(record, '336', '2', ' ', ' ', 'rdacontent')
    update_field_value(record, '337', 'a', ' ', ' ', 'unmediated')
    update_field_value(record, '337', 'b', ' ', ' ', 'n')
    update_field_value(record, '337', '2', ' ', ' ', 'rdamedia')
    update_field_value(record, '338', 'a', ' ', ' ', 'volume')
    update_field_value(record, '338', 'b', ' ', ' ', 'nc')
    update_field_value(record, '338', '2', ' ', ' ', 'rdacarrier')

    # Note
    update_field_value(record, '500', 'a', ' ', ' ', LBMC::SOURCE_NOTE)

    # Subjects
    subject_tags = Array.new(['600','610','611','630','648','650','651','653','655'])
    # Create empty arrays to hold different types of subjects
    subject_hash = Hash.new
    subject_tags.each do |st|
      subject_hash[st.to_s] = Array.new
    end
    # Step through the subjects parameter array and add its value to a subject_hash based on its corresponding subjects_type array value
    sinc = 0
    params[:subject].each do |s|
      subfield_hash = Hash.new
      subfield_hash['a'] = s
      if params[:subject_type].nil?
        subject_hash['653'].push(subfield_hash)
      else
        if params[:subject_type][sinc] != '653'
          subfield_hash['2'] = 'fast'
          subfield_hash['0'] = params[:subject_id][sinc]
        end
        subject_hash[params[:subject_type][sinc]].push(subfield_hash)
      end
      sinc += 1
    end
    # Step through the subject array by tag and add any
    subject_tags.each do |st|
      if subject_hash[st].length > 0
        sind1 = ' '
        sind2 = '7'
        if st == '653'
          sind1 = '0'
          sind2 = ' '
        end
        update_field_array2(record, st, sind1, sind2, subject_hash[st])
      end
    end
    
    # puts record
    
    record
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
  
  def book_fixed_length_data(params)
    fde = MARC::ControlField.new('008')
    fde.value = ''.rjust(40, ' ')
    now = Time.now
    year = now.year.to_s[2,2]
    month = now.month.to_s.rjust(2, '0')
    day = now.day.to_s.rjust(2, '0')
    fde.value[0,6] = "#{year}#{month}#{day}"
    fde.value[6,1] = 's'
    fde.value[7,4] = publication_date_is_positive_number?(params[:publication_date]) ? params[:publication_date].rjust(4,'0') : now.year.to_s
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
    fde.value[35,3] = params[:language]
    fde.value[38,1] = ' '
    fde.value[39,1] = 'd'
    fde
  end
  
  def publication_date_is_positive_number?(publication_date)
    /^-?[1-9]\d*$/ =~ publication_date
  end
  
  def update_marc_record_from_params(marc_record, params)
  
    # puts ; puts pp params ; puts
  
    # Language
    update_control_field_value(marc_record, '008', 35, params[:language])
    
    # Country of publication
    update_control_field_value(marc_record, '008', 15, params[:country_of_publication])
  
    # ISBN
    update_field_array(marc_record, '020', 'a', ' ', ' ', params[:isbn])
  
    # Title

    # Set the first indicator value based on the presence or absence of a 1XX author
    title_indicator_1 = '0'
    if params[:author].length > 0
      if params[:author][0].strip.length > 0
        title_indicator_1 = '1'
      end
    end

    # Non-Latin Scripts in the title
    # Remove 066's and 880's
    update_field_value(marc_record, '066', 'c', ' ', ' ', '')
    update_field_value(marc_record, '245', '6', title_indicator_1, '0', '')
    update_field_value(marc_record, '880', '6', title_indicator_1, '0', '')
    update_field_value(marc_record, '880', 'a', title_indicator_1, '0', '')
    # Detect languages of the title string
    title_languages = detect_script(params[:title])
    # If title is all one language and in a supported non-Latin script, do 245/880 stuff
    if title_languages.length > 0
      title_languages.each do |l|
        update_field_value(marc_record, '066', 'c', ' ', ' ', l)
      end
      update_field_value(marc_record, '245', 'as', title_indicator_1, '0', '')
      update_field_value(marc_record, '245', '6', title_indicator_1, '0', '880-01')
      update_field_value(marc_record, '245', 'a', title_indicator_1, '0', '<>')
      update_field_value(marc_record, '880', '6', title_indicator_1, '0', '245-01/'+title_languages[0])
      update_field_value(marc_record, '880', 'a', title_indicator_1, '0', params[:title])
    else
      # Update the title 
      update_field_value(marc_record, '245', 'a', title_indicator_1, '0', params[:title])
    end
    
    # Author
    # First delete any existing author main entries
    update_field_value(marc_record, '100', 'a', '1', ' ', '')
    update_field_value(marc_record, '110', 'a', '2', ' ', '')
    # Then reset the 1XX based on the current value
    if params[:author].length > 0
      if params[:author_field_0] == "110"
        update_field_value(marc_record, '110', 'a', '2', ' ', params[:author][0])
      else
        update_field_value(marc_record, '100', 'a', '1', ' ', params[:author][0])
      end
    end
    
    # Added Entries
    # First remove any existing 700 and 710 entries
    update_field_array(marc_record, '700', 'a', '2', ' ', '')
    update_field_array(marc_record, '710', 'a', '2', ' ', '')
    # If there is more than one entry in the Authors array
    if params[:author].length > 1
      aeinc = 0
      v700s = Array.new
      v710s = Array.new
      params[:author].each do |a|
        if aeinc > 0
          af = "author_field_"+aeinc.to_s
          if params[af] == "100"
            v700s.push(a)
          else
            v710s.push(a)
          end
        end
        aeinc += 1
      end
      if v700s.length > 0
        update_field_array(marc_record, '700', 'a', '1', ' ', v700s)
      end
      if v710s.length > 0
        update_field_array(marc_record, '710', 'a', '2', ' ', v710s)
      end
    end
    
    # Place of Publication
    update_field_value(marc_record, '264', 'a', ' ', '1', params[:place_of_publication])

    # Publisher
    update_field_value(marc_record, '264', 'b', ' ', '1', params[:publisher])
    
    # Publication date
    update_field_value(marc_record, '264', 'c', ' ', '1', params[:publication_date])
    if publication_date_is_positive_number?(params[:publication_date])
      update_control_field_value(marc_record, '008', 7, params[:publication_date].rjust(4,'0'))
    end
    
    # Extent
    update_field_value(marc_record, '300', 'a', ' ', ' ', params[:extent])
    
    # RDA Content, Media, and Carrier type
    update_field_value(marc_record, '336', 'a', ' ', ' ', 'text')
    update_field_value(marc_record, '336', 'b', ' ', ' ', 'txt')
    update_field_value(marc_record, '336', '2', ' ', ' ', 'rdacontent')
    update_field_value(marc_record, '337', 'a', ' ', ' ', 'unmediated')
    update_field_value(marc_record, '337', 'b', ' ', ' ', 'n')
    update_field_value(marc_record, '337', '2', ' ', ' ', 'rdamedia')
    update_field_value(marc_record, '338', 'a', ' ', ' ', 'volume')
    update_field_value(marc_record, '338', 'b', ' ', ' ', 'nc')
    update_field_value(marc_record, '338', '2', ' ', ' ', 'rdacarrier')

    # Subjects
    subject_tags = Array.new(['600','610','611','630','648','650','651','653','655'])
    # Remove any existing subjects
    subject_tags.each do |st|
      update_field_array(marc_record, st, 'a', '0', ' ', '')
    end
    # Create empty arrays to hold different types of subjects
    subject_hash = Hash.new
    subject_tags.each do |st|
      subject_hash[st.to_s] = Array.new
    end
    # Step through the subjects parameter array and add its value to a subject_hash based on its corresponding subjects_type array value
    sinc = 0
    params[:subject].each do |s|
      subfield_hash = Hash.new
      subfield_hash['a'] = s
      if params[:subject_type].nil?
        subject_hash['653'].push(subfield_hash)
      else
        if params[:subject_type][sinc] != '653'
          subfield_hash['2'] = 'fast'
          subfield_hash['0'] = params[:subject_id][sinc]
        end
        subject_hash[params[:subject_type][sinc]].push(subfield_hash)
      end
      sinc += 1
    end
    # Step through the subject array by tag and add any
    subject_tags.each do |st|
      if subject_hash[st].length > 0
        sind1 = ' '
        sind2 = '7'
        if st == '653'
          sind1 = '0'
          sind2 = ' '
        end
        update_field_array2(marc_record, st, sind1, sind2, subject_hash[st])
      end
    end
    
    # puts marc_record
    marc_record
    
  end
  
  def sort_subfields(marc_record, data_field_number)
    marc_record[data_field_number].subfields.sort_by! {|subfield| subfield.code}
  end
  
  def update_control_field_value(marc_record, control_field_number, starting_position, new_value)
    control_field = marc_record[control_field_number]
    control_field.value[starting_position,new_value.length] = new_value
  end
  
  def update_field_value(marc_record, data_field_number, subfield_code, i1, i2, new_value)
    data_field = marc_record[data_field_number]
    
    # Does the data_field currently exist?
    
    if data_field.nil? # data_field is nil ...
      
      # the data field does not exist yet
      unless new_value.nil? or new_value.strip == ''
        marc_record << MARC::DataField.new(data_field_number, i1, i2, MARC::Subfield.new(subfield_code, new_value))
      end
      
    else # data_field is not nil ...
      
      # if new_value is blank, 
      if new_value.nil? or new_value.strip == ''
        
        if field_is_deletable?(data_field, subfield_code) 
          # delete the data_field from the record if the current subfield is the only one in the field
          marc_record.fields.delete data_field 
        else 
          # Otherwise, delete just the subfield in question.
          subfield = data_field.find_all {|subfield| subfield.code == subfield_code}.first
          data_field.subfields.delete( subfield ) unless subfield.nil?
        end
        
      else # new_value is not blank

        # Update or add the subfield data
        data_field.indicator1 = i1
        data_field.indicator2 = i2
        subfield = data_field.find_all {|subfield| subfield.code == subfield_code}.first
        if !subfield || data_field_number == '066'
          data_field.subfields << MARC::Subfield.new(subfield_code, new_value)
        else
          subfield.value = new_value
        end

      end
    end
    
    if data_field_number == '264' and marc_record[data_field_number]
      sort_subfields(marc_record, data_field_number)
    end
    
  end
  
  def update_field_array(marc_record, data_field_number, subfield_code, i1, i2, new_array)
  
    data_field = marc_record[data_field_number]
    
    # Does at least one occurrence of the data_field currently exist?
    unless data_field.nil? # data_field is not nil ...
      # remove all occurrences of data_field from marc_record
      marc_record.each_by_tag(data_field_number) do |field| 
        marc_record.fields.delete(field)
      end
    end
    
    # add new data_fields for non nil and non-empty members of new_array
    if new_array.kind_of?(Array)
      new_array.each do |new_value|
        unless new_value.nil? or new_value.strip == ''
          marc_record << MARC::DataField.new(data_field_number, i1, i2, MARC::Subfield.new(subfield_code, new_value))
        end
      end
    end
    
  end
  
  def update_field_array2(marc_record, data_field_number, i1, i2, new_array)
  
    data_field = marc_record[data_field_number]
    
    # Does at least one occurrence of the data_field currently exist?
    unless data_field.nil? # data_field is not nil ...
      # remove all occurrences of data_field from marc_record
      marc_record.each_by_tag(data_field_number) do |field| 
        marc_record.fields.delete(field)
      end
    end
    
    # add new data_fields for non nil and non-empty members of new_array
    if new_array.kind_of?(Array)
      new_array.each do |subfield_hash|
        subfields = []
        subfield_hash.each do |key, value|
          subfields.push(MARC::Subfield.new(key,value))
        end
        field = MARC::DataField.new(data_field_number, i1, i2,MARC::Subfield.new('a',subfield_hash['a']))
        unless subfield_hash['0'].nil?
          field.append(MARC::Subfield.new('0',subfield_hash['0']))
        end
        unless subfield_hash['2'].nil?
          field.append(MARC::Subfield.new('2',subfield_hash['2']))
        end
        marc_record << field
      end
    end
    
  end
  
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