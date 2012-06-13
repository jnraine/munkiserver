module NokogiriHelper
  # Retrieve a web page, following any redirects presented. Throws exception
  # for recurisive redirects.
  def retrieve_response(page_url)
    url = URI.parse(page_url)
    response = Net::HTTP.get_response(url)
    prev_redirect = ""
    while response.header['location']
      if prev_redirect == response.header['location']
        raise "Recursive redirect: #{response.header['location']}" 
      end
      prev_redirect = response.header['location']
      url = URI.parse(response.header['location'])
      response = Net::HTTP.get_response(url)
    end
    
    response
  end
  
  def page(page_url)
    uri = URI.parse(page_url)
    response = retrieve_response(page_url)
    Nokogiri::HTML(response.body)
  rescue SocketError
    NullObject.new
  end
  
  # Fetches page and returns redirect URL in location header
  def redirect_url(url_string)
    Net::HTTP.get_response(URI.parse(url_string)).header["location"]
  end

  extend self
end