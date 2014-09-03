# encoding: utf-8
helpers do
  
  def marc_record_from_params(params)
    record = create_book_record
    record << book_fixed_length_data

    # OCLC Symbol
    record << MARC::DataField.new('040', ' ', ' ', MARC::Subfield.new('a', params[:oclc_symbol]), MARC::Subfield.new('c', params[:oclc_symbol]))
    
    # Author
    if params[:author_field] == "100"
      record << MARC::DataField.new('100', '1', ' ', MARC::Subfield.new('a', params[:author]))
    else
      record << MARC::DataField.new('110', '2', ' ', MARC::Subfield.new('a', params[:author]))
    end
    
    # Title
    record << title_statement(params)
    
    # Extent
    if params[:extent] and params[:extent].strip != ''
      record << MARC::DataField.new('300', ' ', ' ', MARC::Subfield.new('a', params[:extent]))
    end
    
    # Note
    record << MARC::DataField.new('500', ' ', ' ', MARC::Subfield.new('a', LBMC::SOURCE_NOTE))

    # Topic
    if params[:subject] and params[:subject].strip != ''
      record << MARC::DataField.new('650', '1', '4', MARC::Subfield.new('a', params[:subject]))
    end
    
    record
  end
  
  def title_statement(params)
    title_stmt = MARC::DataField.new('245', '0', '0')
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
    record.leader[17] = '3'
    record.leader[18] = 'u'
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
    if params[:author].nil? or params[:author].strip == ''
      title_stmt.indicator1 = '0'
    else
      title_stmt.indicator1 = '1'
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
  
  # Escapes HTML
  def h(text)
    Rack::Utils.escape_html(text)
  end
  
end