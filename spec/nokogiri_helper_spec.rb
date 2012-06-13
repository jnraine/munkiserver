require 'spec_helper'

describe NokogiriHelper, :vcr do
  describe ".page" do
    context "given a URL to a page" do
      it "returns a nokogiri document given a URL string"do
        NokogiriHelper.page("http://www.google.com").should be_a(Nokogiri::HTML::Document)
      end
    end

    context "given a URL to a redirect page" do
      it "follows a redirect page and returns a nokogiri document" do
        NokogiriHelper.page("http://www.macupdate.com/app/mac/10700").title.should match("Firefox")
      end
    end
    
    context "give a URL to of a non-existing domain (another problem)" do
      it "returns a NullObject" do
        NokogiriHelper.page("http://www.notasitefoobarbaz.com").should be_nil
      end
    end
  end
  
  describe "redirect_url" do
    context "given a URL with a redirect" do
      it "returns a redirect URL from a URL" do
        NokogiriHelper.redirect_url("http://www.macupdate.com/app/mac/10700").should == "http://www.macupdate.com/app/mac/10700/firefox"
      end
    end
    
    context "given a URL with no redirect" do
      it "returns a redirect URL from a URL" do
        NokogiriHelper.redirect_url("http://www.macupdate.com/app/mac/10700/firefox").should be_nil
      end
    end
  end
end