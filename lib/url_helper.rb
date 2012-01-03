require 'net/http'

module URLHelper
  def final_url(uri_str, limit = 10)
    # You should choose better exception.
    raise ArgumentError, 'HTTP redirect too deep' if limit == 0
    begin
      response = Net::HTTP.get_response(URI.parse(uri_str))
    rescue
      uri_str
    end
    case response
      when Net::HTTPSuccess     then uri_str
      when Net::HTTPRedirection 
        response['location'].match(/^http/) ? final_url(response['location'], limit - 1) : uri_str
      when Net::HTTPMovedPermanently 
        response['location'].match(/^http/) ? final_url(response['location'], limit - 1) : uri_str
      else
      uri_str
    end
  end  
  
end
