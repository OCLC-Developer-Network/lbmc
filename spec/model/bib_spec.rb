require 'spec_helper'

describe Bib do
  context "when testing a record that did not originate in LBMC" do
    before(:all) do
      # Set up @record
    end
    
    it "should not indicate it is LBMC app created" do
      # expect(@record.is_app_created?).to be_false
    end
  end
end