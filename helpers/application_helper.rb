# encoding: utf-8
module ApplicationHelper
  
  def marc_record_from_params(params)
    record = create_book_record
    record << book_fixed_length_data(params)

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
    update_field_value(record, '245', 'a', ' ', ' ', params[:title])
    
    # Publication data
    update_field_value(record, '260', 'b', ' ', ' ', params[:publisher])
    update_field_value(record, '260', 'c', ' ', ' ', params[:publication_date])
    
    # Extent
    update_field_value(record, '300', 'a', ' ', ' ', params[:extent])

    # Note
    update_field_value(record, '500', 'a', ' ', ' ', LBMC::SOURCE_NOTE)

    # Topic
    update_field_value(record, '650', 'a', ' ', ' ', params[:subject])
    
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
    fde.value[35,3] = 'eng'
    fde.value[38,1] = ' '
    fde.value[39,1] = 'd'
    fde
  end
  
  def publication_date_is_positive_number?(publication_date)
    /^-?[1-9]\d*$/ =~ publication_date
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
    
    # Publication date
    update_field_value(marc_record, '260', 'c', ' ', ' ', params[:publication_date])
    if publication_date_is_positive_number?(params[:publication_date]) 
      marc_record['008'].value[7,4] = params[:publication_date].rjust(4,'0')
    end
    
    # Extent
    update_field_value(marc_record, '300', 'a', ' ', ' ', params[:extent])

    # Subject
    update_field_value(marc_record, '650', 'a', '1', '4', params[:subject])
    
    marc_record
  end
  
  def update_field_value(marc_record, data_field_number, subfield_code, i1, i2, new_value)
    data_field = marc_record[data_field_number]
    
    # Does the data_field currently exist?
    if data_field.nil?
      
      # if new_value is blank, there is nothing to delete
      unless new_value.nil? or new_value.strip == ''

        # otherwise, create the data field, add the subfield, add it to the record
        marc_record << MARC::DataField.new(data_field_number, i1, i2, MARC::Subfield.new(subfield_code, new_value))

      end
    else # data_field is not nil...
      
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
  
  # Escapes HTML
  def h(text)
    Rack::Utils.escape_html(text)
  end
  
end