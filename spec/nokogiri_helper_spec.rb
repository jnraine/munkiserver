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
        NokogiriHelper.page("https://www.macupdate.com/app/mac/10700").title.should match("Firefox")
      end
    end
    
    context "given an unescaped URL" do
      it "returns a nokogiri document" do
        NokogiriHelper.page("https://www.macupdate.com/find/mac/Foo App").title.should match("foo")
      end
    end
    
    context "given problematic URLs" do
      it "returns a NullObject" do
        NokogiriHelper.page("http://www.google.com/does/not/exist/returns/404").should be_nil # 404s
      end
    end
  end
  
  describe "redirect_url" do
    context "given a URL with a redirect" do
      it "returns a redirect URL from a URL" do
        NokogiriHelper.redirect_url("https://www.macupdate.com/app/mac/10700").should == "https://www.macupdate.com/app/mac/10700/firefox"
      end
    end
    
    context "given a URL with no redirect" do
      it "returns a redirect URL from a URL" do
        NokogiriHelper.redirect_url("https://www.macupdate.com/app/mac/10700/firefox").should be_nil
      end
    end
  end
end