# encoding: utf-8
helpers do
  
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
      "Common" => /\p{Common}/, 
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
    record << book_fixed_length_data
    
    # Hard coded institution affiliation (symbol: OCPSB)
    record << MARC::DataField.new('040', ' ', ' ', MARC::Subfield.new('a', 'OCPSB'), MARC::Subfield.new('c', 'OCPSB'))
    
    # Author
    record << MARC::DataField.new('100', '0', ' ', MARC::Subfield.new('a', params[:author]))
    
    # Title
    record << title_statement
    
    # Extent
    if params[:extent] and params[:extent].strip != ''
      record << MARC::DataField.new('300', ' ', ' ', MARC::Subfield.new('a', params[:extent]))
    end

    # Topic
    if params[:subject] and params[:subject].strip != ''
      record << MARC::DataField.new('650', '1', '4', MARC::Subfield.new('a', params[:subject]))
    end
  end
  
  def title_statement(params)
    title_stmt = MARC::DataField.new('245', ' ', ' ')
    title_stmt.subfields << MARC::Subfield.new('a', params[:title])
    title_stmt.subfields << MARC::Subfield.new('b', params[:subtitle]) if params[:subtitle] and params[:subtitle].strip != ''
    title_stmt
  end
  
  def create_book_record
    record = MARC::Record.new
    record.leader[0,5] = '00000'
    record.leader[5] = 'n'
    record.leader[6] = 'a'
    record.leader[7] = 'm'
    record.leader[9] = 'a'
    record.leader[17] = '3'
    record.leader[18] = 'a'
    record
  end
  
  def book_fixed_length_data
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
    fde.value[29,1] = '0'
    fde.value[30,1] = '0'
    fde.value[31,1] = '|'
    fde.value[32,1] = ' '
    fde.value[33,1] = '|'
    fde.value[34,1] = '|'
    fde.value[35,3] = 'eng'
    fde.value[38,1] = ' '
    fde.value[39,1] = 'd'
    fde
  end
  
  def update_marc_record_from_params(marc_record, params)
    # Title Statement
    title_stmt = marc_record['245']
    title = title_stmt.find_all {|subfield| subfield.code == 'a'}.first
    title.value = params[:title]
    subtitle = title_stmt.find_all {|subfield| subfield.code == 'b'}.first
    if params[:subtitle].nil? or params[:subtitle].strip == ''
      title_stmt.subfields.delete(subtitle)
    else
      if subtitle.nil?
        title_stmt.subfields << MARC::Subfield.new('b', params[:subtitle])
      else
        subtitle.value = params[:subtitle]
      end
    end
    
    # Author
    update_field_value(marc_record, '100', 'a', ' ', ' ', params[:author])

    # Publisher
    update_field_value(marc_record, '260', 'b', ' ', ' ', params[:publisher])
    
    # Extent
    update_field_value(marc_record, '300', 'a', ' ', ' ', params[:extent])

    # Subject
    update_field_value(marc_record, '650', 'a', '1', '4', params[:subject])
    
    marc_record
  end
  
  def update_field_value(marc_record, data_field_number, subfield_code, i1, i2, new_value)

    data_field = marc_record[data_field_number]
    
    if new_value.nil? or new_value.strip == ''
      
      # Delete the value
      marc_record.fields.delete data_field unless data_field.nil?
      
    else
      # Add the new value
      if data_field.nil?
      
        # Create the data field
        data_field = MARC::DataField.new(data_field_number, i1, i2, MARC::Subfield.new(subfield_code, new_value))
        marc_record << data_field
        
      else
        
        # Update the data field
        subfield = data_field.find_all {|subfield| subfield.code == subfield_code}.first
        subfield.value = new_value
        
      end
    end
  end
  
  def get_data_field
    data_field = MARC::DataField.new(data_field_number, ' ', ' ', MARC::Subfield.new(subfield_code, new_value))
  end
  
  # Escapes HTML
  def h(text)
    Rack::Utils.escape_html(text)
  end
  
end