require 'spec_helper'

describe "the record page" do
  before(:all) do
    @access_token = OCLC::Auth::AccessToken.new('grant_type', ['FauxService'], 128807, 128807)
    @access_token.value = 'tk_faux_token'
    @access_token.expires_at = DateTime.parse("9999-01-01 00:00:00Z")
  end
  
  context "when displaying the form for a new record" do
    before(:all) do
      get '/record/new', params={}, rack_env={ 'rack.session' => {:token => @access_token, :registry_id => 128807} }
      @doc = Nokogiri::HTML(last_response.body)
      @form_element = @doc.xpath("//form[@id='record-form']").first
    end
    
    it "should have a form that submits the correct action" do
      submit_location = @form_element.attr('action')
      uri = URI.parse(submit_location)
      expect(uri.path).to eq('/record/create')
    end
  end
  
  context "when displaying a record created in the LBMC application by the institution" do
    before(:all) do
      stub_request(:get, "http://cataloging-worldcatbib-qa.ent.oclc.org/bib/data/883876185?classificationScheme=LibraryOfCongress").
        to_return(:status => 200, :body => mock_file_contents("ocn883876185.atomxml"))
      get '/record/883876185', params={}, rack_env={ 'rack.session' => {:token => @access_token, :registry_id => 128807} }
      @doc = Nokogiri::HTML(last_response.body)
      @form_element = @doc.xpath("//form[@id='record-form']").first
    end

    it "should display a form" do
      expect(@form_element).not_to be_nil
    end
    
    it "should display a form with the correct action" do
      submit_location = @form_element.attr('action')
      uri = URI.parse(submit_location)
      expect(uri.path).to eq('/record/update')
    end
    
    it "should have a hidden input field containing the OCLC number" do
      input = @form_element.xpath(".//input[@name='oclc_number'][@type='hidden']").first
      expect(input.attr('value')).to eq('883876185')
    end
    
    it "should have a title input field with the right value" do
      input = @form_element.xpath(".//input[@name='title']").first
      expect(input.attr('value')).to eq('Testing metadata APIs')
    end

    it "should have an author input field with the right value" do
      input = @form_element.xpath(".//input[@name='author']").first
      expect(input.attr('value')).to eq('Meyer, Stephen')
    end
    
    it "should have a language select box with the right language selecte" do
      option = @form_element.xpath(".//option[@selected='selected']").first
      expect(option.attr('value')).to eq('eng')
    end

    it "should have a publisher input field with the right value" do
      input = @form_element.xpath(".//input[@name='publisher']").first
      expect(input.attr('value')).to eq('OCLC Press')
    end

    it "should have an extent input field with the right value" do
      input = @form_element.xpath(".//input[@name='extent']").first
      expect(input.attr('value')).to eq('190 p.')
    end

    it "should have a subject input field with the right value" do
      input = @form_element.xpath(".//input[@name='subject']").first
      expect(input.attr('value')).to eq('Application Programming Interfaces (APIs)')
    end
    
    it "should have an isbn input field with the right value" do
      input = @form_element.xpath(".//input[@name='isbn']").first
      expect(input.attr('value')).to eq('9780060723804')
    end
    
    it "should display the MARC record" do
      marc_str = mock_file_contents("ocn883876185.marc")
      marc_pre_element = @doc.xpath("//pre[@id='marc-view']").first
      expect(marc_pre_element.text).to eq(marc_str)
    end
    
    it "should have a link to view the record in WorldCat" do
      xpath = "//a[@id='marc-worldcat-link']"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
    
    it "should have a link to download MARC XML" do
      xpath = "//a[@id='marc-view-link']"
      expect(@doc.xpath(xpath).size).to eq(1)
    end

    it "should have a link to the home page" do
      xpath = "//a[@id='home']"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
    
    it "should have a link to create a new record" do
      xpath = "//a[@id='create']"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
    
    it "should have a link to logoff" do
      xpath = "//a[@id='logoff']"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
    
    it "should provide a download link to the MARC/XML version" do
      marc_xml_link = @doc.xpath("//a[@id='marc-xml-link']").first
      uri = URI.parse(marc_xml_link.attr('href'))
      expect(uri.path).to eq('/record/883876185.xml')
    end
    
  end
  
  context "when submitting an update to change the author name" do
    before(:all) do
      stub_request(:put, "http://cataloging-worldcatbib-qa.ent.oclc.org/bib/data?classificationScheme=LibraryOfCongress").
          to_return(:status => 201, :body => mock_file_contents("ocn883876185-updated.atomxml"))
      stub_request(:get, "http://cataloging-worldcatbib-qa.ent.oclc.org/bib/data/883876185?classificationScheme=LibraryOfCongress").
          to_return(:status => 200, :body => mock_file_contents("ocn883876185-updated.atomxml"))

      p = { 
            :oclc_number => '883876185',
            :language => 'eng',
            :title => 'Testing metadata APIs',
            :subtitle => 'A comparative analysis',
            :author => 'Meyer, Steve',
            :publisher => 'OCLC Press',
            :extent => '190 p.',
            :subject => 'Application Programming Interfaces (APIs)'
          }
      post( '/record/update', params=p, rack_env={ 'rack.session' => {:token => @access_token} } )
    end
    
    it "should respond with a redirect back to the record display page" do
      expect(last_response.redirect?)
      expect(last_response.header['Location']).to eq("http://example.org/record/883876185")
    end
  end
  
  context "when submitting a new record" do
    before(:all) do
      stub_request(:post, "http://cataloging-worldcatbib-qa.ent.oclc.org/bib/data?classificationScheme=LibraryOfCongress").
          to_return(:status => 201, :body => mock_file_contents("ocn883876185.atomxml"))
      stub_request(:get, "http://cataloging-worldcatbib-qa.ent.oclc.org/bib/data/883876185?classificationScheme=LibraryOfCongress").
          to_return(:status => 200, :body => mock_file_contents("ocn883876185.atomxml"))

      p = { 
            :language => 'eng',
            :title => 'Testing metadata APIs',
            :subtitle => 'A comparative analysis',
            :author => 'Meyer, Stephen',
            :publisher => 'OCLC Press',
            :extent => '190 p.',
            :subject => 'Application Programming Interfaces (APIs)'
          }
      post( '/record/create', params=p, rack_env={ 'rack.session' => {:token => @access_token, :registry_id => 128807} } )
    end
    
    it "should respond with a redirect to the record display page" do
      expect(last_response.redirect?)
      expect(last_response.header['Location']).to eq("http://example.org/record/883876185")
    end
  end

  context "when trying to create a new record without a title" do
    before(:all) do
      stub_request(:post, "http://cataloging-worldcatbib-qa.ent.oclc.org/bib/data?classificationScheme=LibraryOfCongress").
          to_return(:status => 409, :body => mock_file_contents("titleless-input-response.marcxml"))

      p = { 
            :language => 'eng',
            :subtitle => 'A comparative analysis',
            :author => 'Meyer, Stephen',
            :publisher => 'OCLC Press',
            :extent => '190 p.',
            :subject => 'Application Programming Interfaces (APIs)'
          }
      post( '/record/create', params=p, rack_env={ 'rack.session' => {:token => @access_token, :registry_id => 128807} } )
      doc = Nokogiri::HTML(last_response.body)
      @alert = doc.xpath("//div[@id='errors']").first
    end
    
    it "should not redirect to the record display page" do
      expect(last_response.redirect?).to eq(false)
    end
    
    it "should display the error section" do
      expect(@alert.xpath("./span[@id='error-heading'][text()='Sorry, but the LBMC Pilot system encountered a problem.']").size).to eq(1)
    end
    
    it "should display the error summary" do
      summary_paragraph = @alert.xpath("./p[@id='summary']")
      expect(summary_paragraph.size).to eq(1)
      expect(summary_paragraph.first.text).to eq('Record is invalid')
    end

    it "should display a list of validation errors" do
      expect(@alert.xpath("./ul/li").size).to eq(2)
    end
    
    it "should display the correct validation message for the first error" do
      expect(@alert.xpath("./ul/li").first.text).to eq('$a in 245 or $k in 245 must be present.')
    end
    
    it "should display the correct validation message for the second error" do
      expect(@alert.xpath("./ul/li").last.text).to eq('Invalid code in indicator 2 in 1st 650')
    end
  end
  
  context "when displaying a record not created in the LBMC application" do
    before(:all) do
      stub_request(:get, "http://cataloging-worldcatbib-qa.ent.oclc.org/bib/data/9999999?classificationScheme=LibraryOfCongress").
        to_return(:status => 200, :body => mock_file_contents("ocm09999999.atomxml"))
      get '/record/9999999', params={}, rack_env={ 'rack.session' => {:token => @access_token, :registry_id => 128807} }
      @doc = Nokogiri::HTML(last_response.body)
    end

    it "should not display a form" do
      expect(@doc.xpath("//form[@id='record-form']").first).to be_nil
    end
    
    it "should display an alert info message" do
      xpath = "//div[@class='alert alert-info']"
      expect(@doc.xpath(xpath)).not_to be_empty
    end
    
    it "should have a table cell containing the OCLC number" do
      td = @doc.xpath("//td[@id='oclcnum']").first
      expect(td.text.strip).to eq('9999999')
    end
    
    it "should have a table cell containing the title" do
      td = @doc.xpath("//td[@id='title']").first
      expect(td.text.strip).to eq('Patronage impact of possible future line extensions :')
    end
    
    it "should have a table cell containing the author" do
      td = @doc.xpath("//td[@id='author']").first
      expect(td.text.strip).to eq('')
    end
    
    it "should have a table cell containing the publisher" do
      td = @doc.xpath("//td[@id='publisher']").first
      expect(td.text.strip).to eq('Southern California Rapid Transit District,')
    end
    
    it "should have a table cell containing the publication date" do
      td = @doc.xpath("//td[@id='publication_date']").first
      expect(td.text.strip).to eq('[1981]')
    end
    
    it "should have a table cell containing the extent" do
      td = @doc.xpath("//td[@id='extent']").first
      expect(td.text.strip).to eq('vii, 161 leaves :')
    end
    
    it "should have a table cell containing the language" do
      td = @doc.xpath("//td[@id='language']").first
      expect(td.text.strip).to eq('English')
    end
    
    it "should have a table cell containing the isbn" do
      td = @doc.xpath("//td[@id='isbn']").first
      expect(td.text.strip).to eq('')
    end
    
    it "should display the MARC record" do
      marc_str = mock_file_contents("ocm09999999.marc")
      marc_pre_element = @doc.xpath("//pre[@id='marc-view']").first
      expect(marc_pre_element.text).to eq(marc_str)
    end
    
    it "should have a link to view the record in WorldCat" do
      xpath = "//a[@id='marc-worldcat-link']"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
    
    it "should have a link to download MARC XML" do
      xpath = "//a[@id='marc-view-link']"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
    
    it "should have a link to the home page" do
      xpath = "//a[@id='home']"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
    
    it "should have a link to create a new record" do
      xpath = "//a[@id='create']"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
    
    it "should have a link to logoff" do
      xpath = "//a[@id='logoff']"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
    
  end
  
  context "when displaying a record created in the LBMC application by another institution" do
    before(:all) do
      stub_request(:get, "http://cataloging-worldcatbib-qa.ent.oclc.org/bib/data/883880805?classificationScheme=LibraryOfCongress").
        to_return(:status => 200, :body => mock_file_contents("ocn883880805.atomxml"))
      get '/record/883880805', params={}, rack_env={ 'rack.session' => {:token => @access_token, :registry_id => 128807} }
      @doc = Nokogiri::HTML(last_response.body)
    end

    it "should not display a form" do
      expect(@doc.xpath("//form[@id='record-form']").first).to be_nil
    end
    
    it "should display an alert info message" do
      xpath = "//div[@class='alert alert-info']"
      expect(@doc.xpath(xpath)).not_to be_empty
    end
    
    it "should have a table cell containing the OCLC number" do
      td = @doc.xpath("//td[@id='oclcnum']").first
      expect(td.text.strip).to eq('883880805')
    end
    
    it "should have a table cell containing the title" do
      td = @doc.xpath("//td[@id='title']").first
      expect(td.text.strip).to eq('Test Driven Development for AuthNZ Enforcement')
    end
    
    it "should have a table cell containing the author" do
      td = @doc.xpath("//td[@id='author']").first
      expect(td.text.strip).to eq('Bruce Washburn')
    end
    
    it "should have a table cell containing the publisher" do
      td = @doc.xpath("//td[@id='publisher']").first
      expect(td.text.strip).to eq('')
    end
    
    it "should have a table cell containing the publication date" do
      td = @doc.xpath("//td[@id='publication_date']").first
      expect(td.text.strip).to eq('')
    end
    
    it "should have a table cell containing the extent" do
      td = @doc.xpath("//td[@id='extent']").first
      expect(td.text.strip).to eq('60 p.')
    end
    
    it "should have a table cell containing the language" do
      td = @doc.xpath("//td[@id='language']").first
      expect(td.text.strip).to eq('English')
    end
    
    it "should have a table cell containing the isbn" do
      td = @doc.xpath("//td[@id='isbn']").first
      expect(td.text.strip).to eq('')
    end
    
    it "should display the MARC record view" do
      marc_str = mock_file_contents("ocn883880805.marc")
      marc_pre_element = @doc.xpath("//pre[@id='marc-view']").first
      expect(marc_pre_element.text).to eq(marc_str)
    end
    
    it "should have a link to view the record in WorldCat" do
      xpath = "//a[@id='marc-worldcat-link']"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
    
    it "should have a link to download MARC XML" do
      xpath = "//a[@id='marc-view-link']"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
    
    it "should have a link to the home page" do
      xpath = "//a[@id='home']"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
    
    it "should have a link to create a new record" do
      xpath = "//a[@id='create']"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
    
    it "should have a link to logoff" do
      xpath = "//a[@id='logoff']"
      expect(@doc.xpath(xpath).size).to eq(1)
    end
    
  end
  
  context "when downloading a MARC record" do  
    context "as MARC/XML" do
      before(:all) do
        stub_request(:get, "http://cataloging-worldcatbib-qa.ent.oclc.org/bib/data/883876185?classificationScheme=LibraryOfCongress").
          to_return(:status => 200, :body => mock_file_contents("ocn883876185.atomxml"))
        get '/record/883876185.xml', params={}, rack_env={ 'rack.session' => {:token => @access_token, :registry_id => 128807} }
        raw_marc = StringIO.new( last_response.body )
        @record = MARC::XMLReader.new(raw_marc).first
      end
    
      it "should have a content type of application/xml" do
        expect(last_response.header["Content-Type"]).to eq("application/xml;charset=utf-8")
      end
    
      it "should return a parseable MARC record" do
        expect(@record).to be_instance_of(MARC::Record)
      end
    
      it "should return a MARC record with the right data" do
        expect(@record['001'].value).to eq('ocn883876185')
      end
    end
     
  end
  
  context "when trying to display an OCLC number that does not exist" do
    before(:all) do
      stub_request(:get, "http://cataloging-worldcatbib-qa.ent.oclc.org/bib/data/99999999999999?classificationScheme=LibraryOfCongress").
        to_return(:status => 404, :body => mock_file_contents("record_not_found.xml"))
      get '/record/99999999999999', params={}, rack_env={ 'rack.session' => {:token => @access_token, :registry_id => 128807} }
      doc = Nokogiri::HTML(last_response.body)
      @alert = doc.xpath("//div[@id='errors']").first
    end

    it "should display the error section" do
      expect(@alert.xpath("./span[@id='error-heading'][text()='Sorry, but the LBMC Pilot system encountered a problem.']").size).to eq(1)
    end

  end
end
