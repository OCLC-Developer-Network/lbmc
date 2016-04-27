# Bib It -- a low barrier tool for metadata creation

Bib It is a web-based application for creating bibliographic records in OCLC's WorldCat database, specifically designed for use by non-librarians and for creating initial cataloging records describing non-Latin script materials.

It is a client application that is dependent on OCLC's WorldCat Metadata API as its means of initiating record creation. See the API Key Requirements below for more details.

## Installation

### Step 1: Download the App & Install Dependencies

```bash
$ git clone https://github.com/OCLC-Developer-Network/lbmc.git
$ bundle install
```

### Step 2: Configure the App

Next you will need to modify the configuration files. Save a copy of the YAML files in the `config/` directory without the ".example" portion of the name. The config files the app expects to find are ignored so that real API key information is not checked into the repository.

Add the API key details to `wskey.yml` and add your institution's registry ID, OCLC symbol and name to the `lbmc.yml` file.

### Usage

Run the application:

```bash
$ bundle exec rackup
```

And then point your web browser at the URL:

[http://localhost:9292](http://localhost:9292)

## API Key Requirements

You will need an [OCLC Web Service Key](http://www.oclc.org/developer/develop/authentication/what-is-a-wskey.en.html) (WSKey) with access to the [WorldCat Metadata API](http://www.oclc.org/developer/develop/web-services/worldcat-metadata-api.en.html).

This API key will need to be configured with a redirect URI that points to the `catch_auth_code` handler for the app. So if you are going to run this on localhost per these instructions, the redirect URI value for your WSKey should be set to `http://localhost:9292/catch_auth_code`.

## Support

While OCLC does not plan to modify or enhance this application, we encourage others to do so under the terms of its Apache License.  If you have questions please contact the [OCLC Developer Network](https://www.oclc.org/developer/forms/contact-us.en.html).

The Bib It application is limited to a subset of the full range of character encodings supported by OCLC. It automatically detects input to determine if a script outside of that subset is entered, and it automatically generates the proper character encoding representation in 880 $6 for scripts within that subset.  The application source can be modified to support additional scripts. For more information, consult [Issue #1](https://github.com/OCLC-Developer-Network/lbmc/issues/1) in the GitHub repository.


