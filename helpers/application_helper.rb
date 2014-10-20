# encoding: utf-8
module ApplicationHelper

  def script_identifier
    {
      "Arabic" => "(3",
      "Armenian" => "Armn",
      "Bengali" => "Beng",
      "Cyrillic" => "(N",
      "Devangari" => "Deva",
      "Ethiopic" => "Ethi",
      "Greek" => "(S",
      "Han" => "$1",
      "Hangul" => "$1",
      "Hebrew" => "(2",
      "Hiragana" => "$1",
      "Katakana" => "$1",
      "Syriac" => "Syrc",
      "Tamil" => "Taml",
      "Thai" => "Thai"
    }
  end

  def supported_languages 
    [ 
      "Arabic",
      "Armenian",
      "Bengali",
      #"Common",
      "Cyrillic",
      "Devangari",
      "Ethiopic",
      "Greek",
      "Han",
      "Hangul",
      "Hebrew",
      "Hiragana",
      "Katakana",
      "Latin",
      "Syriac",
      "Tamil",
      "Thai"
    ]
  end

  def languages
    {
      "Arabic" => /\p{Arabic}/, 
      "Armenian" => /\p{Armenian}/, 
      "Balinese" => /\p{Balinese}/, 
      "Bengali" => /\p{Bengali}/, 
      "Bopomofo" => /\p{Bopomofo}/, 
      "Braille" => /\p{Braille}/, 
      "Buginese" => /\p{Buginese}/, 
      "Buhid" => /\p{Buhid}/, 
      "Canadian_Aboriginal" => /\p{Canadian_Aboriginal}/, 
      "Carian" => /\p{Carian}/, 
      "Cham" => /\p{Cham}/, 
      "Cherokee" => /\p{Cherokee}/, 
      #"Common" => /\p{Common}/, 
      "Coptic" => /\p{Coptic}/, 
      "Cuneiform" => /\p{Cuneiform}/, 
      "Cypriot" => /\p{Cypriot}/, 
      "Cyrillic" => /\p{Cyrillic}/, 
      "Deseret" => /\p{Deseret}/, 
      "Devanagari" => /\p{Devanagari}/, 
      "Ethiopic" => /\p{Ethiopic}/, 
      "Georgian" => /\p{Georgian}/, 
      "Glagolitic" => /\p{Glagolitic}/, 
      "Gothic" => /\p{Gothic}/, 
      "Greek" => /\p{Greek}/, 
      "Gujarati" => /\p{Gujarati}/, 
      "Gurmukhi" => /\p{Gurmukhi}/, 
      "Han" => /\p{Han}/, 
      "Hangul" => /\p{Hangul}/, 
      "Hanunoo" => /\p{Hanunoo}/, 
      "Hebrew" => /\p{Hebrew}/, 
      "Hiragana" => /\p{Hiragana}/, 
      "Inherited" => /\p{Inherited}/, 
      "Kannada" => /\p{Kannada}/, 
      "Katakana" => /\p{Katakana}/, 
      "Kayah_Li" => /\p{Kayah_Li}/, 
      "Kharoshthi" => /\p{Kharoshthi}/, 
      "Khmer" => /\p{Khmer}/, 
      "Lao" => /\p{Lao}/, 
      "Latin" => /\p{Latin}/, 
      "Lepcha" => /\p{Lepcha}/, 
      "Limbu" => /\p{Limbu}/, 
      "Linear_B" => /\p{Linear_B}/, 
      "Lycian" => /\p{Lycian}/, 
      "Lydian" => /\p{Lydian}/, 
      "Malayalam" => /\p{Malayalam}/, 
      "Mongolian" => /\p{Mongolian}/, 
      "Myanmar" => /\p{Myanmar}/, 
      "New_Tai_Lue" => /\p{New_Tai_Lue}/, 
      "Nko" => /\p{Nko}/, 
      "Ogham" => /\p{Ogham}/, 
      "Ol_Chiki" => /\p{Ol_Chiki}/, 
      "Old_Italic" => /\p{Old_Italic}/, 
      "Old_Persian" => /\p{Old_Persian}/, 
      "Oriya" => /\p{Oriya}/, 
      "Osmanya" => /\p{Osmanya}/, 
      "Phags_Pa" => /\p{Phags_Pa}/, 
      "Phoenician" => /\p{Phoenician}/, 
      "Rejang" => /\p{Rejang}/, 
      "Runic" => /\p{Runic}/, 
      "Saurashtra" => /\p{Saurashtra}/, 
      "Shavian" => /\p{Shavian}/, 
      "Sinhala" => /\p{Sinhala}/, 
      "Sundanese" => /\p{Sundanese}/, 
      "Syloti_Nagri" => /\p{Syloti_Nagri}/, 
      "Syriac" => /\p{Syriac}/, 
      "Tagalog" => /\p{Tagalog}/, 
      "Tagbanwa" => /\p{Tagbanwa}/, 
      "Tai_Le" => /\p{Tai_Le}/, 
      "Tamil" => /\p{Tamil}/, 
      "Telugu" => /\p{Telugu}/, 
      "Thaana" => /\p{Thaana}/, 
      "Thai" => /\p{Thai}/, 
      "Tibetan" => /\p{Tibetan}/, 
      "Tifinagh" => /\p{Tifinagh}/, 
      "Ugaritic" => /\p{Ugaritic}/, 
      "Vai" => /\p{Vai}/, 
      "Yi" => /\p{Yi}/
    }
  end
  
  def detect_language(str)
    matches = Array.new
    languages.each do |lang, lang_regex|
      matches << lang if str =~ lang_regex
    end
    matches
  end
  
  def marc_record_from_params(params)
    record = create_book_record
    record << book_fixed_length_data(params)
    
    # ISBN
    update_field_value(record, '020', 'a', ' ', ' ', params[:isbn])

    # OCLC Symbol
    update_field_value(record, '040', 'a', ' ', ' ', params[:oclc_symbol])
    update_field_value(record, '040', 'c', ' ', ' ', params[:oclc_symbol])
    
    # Author
    if params[:author_field] == "100"
      update_field_value(record, '100', 'a', '1', ' ', params[:author])
    else
      update_field_value(record, '110', 'a', '2', ' ', params[:author])
    end
    
    # Title
    
    # Set the first indicator value based on the presence or absence of a 1XX author
    indicator1 = '1'
    if params[:author].nil? or params[:author].strip == ''
      indicator1 = '0'
    end

    # Update the title 
    update_field_value(record, '245', 'a', indicator1, '0', params[:title])
    
    # Detect language of the title string
    title_languages = detect_language(params[:title])

    # If title is all one language and in a supported non-Latin script, do 245/880 stuff
    if title_languages.length == 1 and title_languages[0] != "Latin" and supported_languages.include?(title_languages[0])
      update_field_value(record, '066', 'c', ' ', ' ', script_identifier[title_languages[0]])
      update_field_value(record, '245', 'a', indicator1, '0', '')
      update_field_value(record, '245', '6', indicator1, '0', '880-01')
      update_field_value(record, '245', 'a', indicator1, '0', '<>')
      update_field_value(record, '880', '6', indicator1, '0', '245-01/'+script_identifier[title_languages[0]])
      update_field_value(record, '880', 'a', indicator1, '0', params[:title])
    end
    
    # Publication data
    update_field_value(record, '260', 'a', ' ', ' ', params[:place_of_publication])
    update_field_value(record, '260', 'b', ' ', ' ', params[:publisher])
    update_field_value(record, '260', 'c', ' ', ' ', params[:publication_date])
    
    # Extent
    update_field_value(record, '300', 'a', ' ', ' ', params[:extent])

    # Note
    update_field_value(record, '500', 'a', ' ', ' ', LBMC::SOURCE_NOTE)

    # Topic
    update_field_value(record, '653', 'a', '1', '0', params[:subject])
    
    record
  end
  
  def create_book_record
    record = MARC::Record.new
    record.leader[0,5] = '00000'
    record.leader[5] = 'n'
    record.leader[6] = 'a'
    record.leader[7] = 'm'
    record.leader[17] = '3'
    record.leader[18] = 'u'
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
  
    puts ; puts pp params ; puts
  
    # Language
    update_control_field_value(marc_record, '008', 35, params[:language])
  
    # ISBN
    update_field_value(marc_record, '020', 'a', ' ', ' ', params[:isbn])
  
    # Title
    
    # Set the first indicator value based on the presence or absence of a 1XX author
    indicator1 = '1'
    if params[:author].nil? or params[:author].strip == ''
      indicator1 = '0'
    end
    
    # Detect language of the title string
    title_languages = detect_language(params[:title])
    if title_languages.length == 1 and title_languages[0] == "Latin"
      # remove any 066 and 880 fields
      update_field_value(marc_record, '066', 'c', ' ', ' ', '')
      update_field_value(marc_record, '245', '6', indicator1, '0', '')
      update_field_value(marc_record, '880', '6', indicator1, '0', '')
      update_field_value(marc_record, '880', 'a', indicator1, '0', '')
    else
      # params[:title] = title_languages.join(", ")
      title_languages.each { |x|
        unless supported_languages.include?(x)
          # params[:title] += " Language " + x + " is unsupported"
        end
      }
    end
    
    # Update the title 
    update_field_value(marc_record, '245', 'a', indicator1, '0', params[:title])

    # If title is all one language and in a supported non-Latin script, do 245/880 stuff
    if title_languages.length == 1 and title_languages[0] != "Latin" and supported_languages.include?(title_languages[0])
      update_field_value(marc_record, '066', 'c', ' ', ' ', script_identifier[title_languages[0]])
      update_field_value(marc_record, '245', 'a', indicator1, '0', '')
      update_field_value(marc_record, '245', '6', indicator1, '0', '880-01')
      update_field_value(marc_record, '245', 'a', indicator1, '0', '<>')
      update_field_value(marc_record, '880', '6', indicator1, '0', '245-01/'+script_identifier[title_languages[0]])
      update_field_value(marc_record, '880', 'a', indicator1, '0', params[:title])
    end
    
    # Author
    # First use update_field_value to delete an erroneously cataloged 
    # 100 or 110 by sending the method a blank value.
    # Then use the same method to add or update the 100 or 110 $a value.
    if params[:author_field] == "100"
      update_field_value(marc_record, '110', 'a', '2', ' ', '')
      update_field_value(marc_record, '100', 'a', '1', ' ', params[:author])
    else
      update_field_value(marc_record, '100', 'a', '1', ' ', '')
      update_field_value(marc_record, '110', 'a', '2', ' ', params[:author])
    end
    
    # Place of Publication
    update_field_value(marc_record, '260', 'a', ' ', ' ', params[:place_of_publication])

    # Publisher
    update_field_value(marc_record, '260', 'b', ' ', ' ', params[:publisher])
    
    # Publication date
    update_field_value(marc_record, '260', 'c', ' ', ' ', params[:publication_date])
    if publication_date_is_positive_number?(params[:publication_date])
      update_control_field_value(marc_record, '008', 7, params[:publication_date].rjust(4,'0'))
    end
    
    # Extent
    update_field_value(marc_record, '300', 'a', ' ', ' ', params[:extent])

    # Subject
    update_field_value(marc_record, '653', 'a', '1', '0', params[:subject])
    
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

        # Update or the subfield data
        subfield = data_field.find_all {|subfield| subfield.code == subfield_code}.first
        if subfield
          subfield.value = new_value
        else
          data_field.subfields << MARC::Subfield.new(subfield_code, new_value)
        end

      end
    end
    
    if data_field_number == '260' and marc_record[data_field_number]
      sort_subfields(marc_record, data_field_number)
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