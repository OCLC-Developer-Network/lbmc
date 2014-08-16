class Bib
  attr_accessor :id, :institution_id, :request_body, :response_code,
      :response_body, :access_token, :wskey, :doc, :marc_record, :errors
      
  def initialize(id, access_token = nil)
    @errors = Array.new
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
    if @doc.xpath('/atom:entry/atom:link', 'atom' => 'http://www.w3.org/2005/Atom').first.attr('href')
      @doc.xpath('/atom:entry/atom:link', 'atom' => 'http://www.w3.org/2005/Atom').first.attr('href')
    else
      nil
    end
  end
  
  def create
    url = "#{base_url}/#{@id}?classificationScheme=LibraryOfCongress"
    auth = "Bearer #{access_token.value}"
    payload = "<?xml version=\"1.0\"?>\n" + @marc_record.to_xml.to_s
    
    resource = RestClient::Resource.new(url)
    resource.post(payload, :authorization => auth, 
        :content_type => 'application/vnd.oclc.marc21+xml',
        :accept => 'application/atom+xml;content="application/vnd.oclc.marc21+xml"') do |response, request, result|
      # puts ; puts request.inspect ; puts
      # puts ; puts response ; puts
      # puts ; puts result.inspect ; puts
      # puts ; puts response.headers ; puts
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
        :accept => 'application/atom+xml;content="application/vnd.oclc.marc21+xml"') do |response, request, result|
      # puts ; puts request.inspect ; puts
      # puts ; puts response ; puts
      # puts ; puts result.inspect ; puts
      # puts ; puts response.headers ; puts
      @response_body = response
      @response_code = result.code
    end
    
    parse_marc if @response_code == '200'
  end
  
  def update
    url = "#{base_url}?classificationScheme=LibraryOfCongress"
    auth = "Bearer #{access_token.value}" 
    payload = "<?xml version=\"1.0\"?>\n" + @marc_record.to_xml.to_s
    
    resource = RestClient::Resource.new(url)
    resource.put(payload, :authorization => auth, 
        :content_type => 'application/vnd.oclc.marc21+xml',
        :accept => 'application/atom+xml;content="application/vnd.oclc.marc21+xml"') do |response, request, result|
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
    
  end
end