module NokogiriHelper
  def page(page_url)
    response = Nokogiri::HTML(open(page_url))
  rescue SocketError
    NullObject.new
  end
  
  # Fetches page and returns redirect URL in location header
  def redirect_url(url_string)
    Net::HTTP.get_response(URI.parse(url_string)).header["location"]
  end

  extend self
end

class NokogiriHelperError < Exception; end
