# LBMC

Low Barrier to Metadata Creation Sample App

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


