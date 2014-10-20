class Bib
  attr_accessor :id, :institution_id, :request_body, :response_code,
      :response_body, :access_token, :wskey, :doc, :marc_record, :error
      
  def initialize(id, access_token = nil)
    @access_token = access_token
    @id = id
    read if id != nil
  end
  
  def self.new_from_marc(marc_record, access_token)
    bib = Bib.new(nil, access_token)
    bib.marc_record = marc_record
    bib.access_token = access_token
    bib
  end
  
  def link
    if @doc.xpath('/atom:entry/atom:link', 'atom' => 'http://www.w3.org/2005/Atom').first
      @doc.xpath('/atom:entry/atom:link', 'atom' => 'http://www.w3.org/2005/Atom').first.attr('href')
    else
      nil
    end
  end
  
  def create
    url = "#{base_url}#{@id}?classificationScheme=LibraryOfCongress"
    auth = "Bearer #{access_token.value}"
    payload = "<?xml version=\"1.0\"?>\n" + @marc_record.to_xml.to_s
    
    resource = RestClient::Resource.new(url)
    resource.post(payload, :authorization => auth, 
        :content_type => LBMC::MARC_XML_MIMETYPE,
        :accept => LBMC::ATOM_WRAPPED_MARC_MIMETYPE) do |response, request, result|
      puts ; puts request.inspect ; puts
      puts ; puts response ; puts
      puts ; puts result.inspect ; puts
      puts ; puts response.headers ; puts
      @response_body = response
      @response_code = result.code
    end
    
    if @response_code == '200' or @response_code == '201' or @response_code == '409'
      load_doc
      parse_marc
      parse_errors
    end
  end
  
  def read
    url = "#{base_url}/#{@id}?classificationScheme=LibraryOfCongress"
    auth = "Bearer #{access_token.value}" 
    
    resource = RestClient::Resource.new(url)
    resource.get(:authorization => auth, 
        :accept => LBMC::ATOM_WRAPPED_MARC_MIMETYPE) do |response, request, result|
      puts ; puts request.inspect ; puts
      puts ; puts response ; puts
      puts ; puts result.inspect ; puts
      puts ; puts response.headers ; puts
      @response_body = response
      @response_code = result.code
    end
    
    if @response_code == '200'
      parse_marc
    elsif @response_code == '404'
      load_doc
      parse_errors
    end
  end
  
  def update
    url = "#{base_url}?classificationScheme=LibraryOfCongress"
    auth = "Bearer #{access_token.value}" 
    payload = "<?xml version=\"1.0\"?>\n" + @marc_record.to_xml.to_s
    
    resource = RestClient::Resource.new(url)
    resource.put(payload, :authorization => auth, 
        :content_type => LBMC::MARC_XML_MIMETYPE,
        :accept => LBMC::ATOM_WRAPPED_MARC_MIMETYPE) do |response, request, result|
      puts ; puts request.inspect ; puts
      puts ; puts response ; puts
      puts ; puts result.inspect ; puts
      puts ; puts response.headers ; puts
      @response_body = response
      @response_code = result.code
    end
    
    if @response_code == '200' or @response_code == '201' or @response_code == '409'
      load_doc
      parse_marc
      parse_errors
    end
  end
  
  def is_app_created?
    @marc_record.fields('500').reduce(false) do |result, element|
      if element['a'] == LBMC::SOURCE_NOTE
        result = true
      end
    end
  end
  
  protected
  
  def base_url
    BASE_URL
  end
  
  def parse_marc
    load_doc if @doc.nil?
    marcxml = @doc.xpath('/atom:entry/atom:content/rb:response/marc:record', 
        'atom' => 'http://www.w3.org/2005/Atom', 
        'rb' => 'http://worldcat.org/rb', 
        'marc' => 'http://www.loc.gov/MARC21/slim').to_xml
    
    reader = MARC::XMLReader.new(StringIO.new(marcxml), :parser => 'nokogiri')
    @marc_record = reader.first
  end
  
  def load_doc
    @doc = Nokogiri::XML(@response_body)
  end
  
  def parse_errors
    error = @doc.xpath('//oclc:error', 
        'atom' => 'http://www.w3.org/2005/Atom', 
        'oclc' => 'http://worldcat.org/xmlschemas/response')

    if error.size > 0
      message = error.xpath('./oclc:message', 
          'oclc' => 'http://worldcat.org/xmlschemas/response').first.text
      oclc_error = OCLCError.new(message)
      error.xpath('./oclc:detail/validationErrors/validationError', 
          'oclc' => 'http://worldcat.org/xmlschemas/response').each do |ve|
        validation_error = ValidationError.new
        validation_error.type = ve.attr('type')
        validation_error.field = ve.xpath('./field').attr('name').value
        validation_error.occurrence = ve.xpath('./field').attr('occurrence').value
        validation_error.message = ve.xpath('./message').first.text
        oclc_error.validation_errors << validation_error
      end
      self.error = oclc_error
    end
  end
    
end