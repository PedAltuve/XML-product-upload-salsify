require 'net/http'
require 'json'
require 'uri'

class SalsifyApiClient
  BASE_URL = 'https://app.salsify.com/api/v1/'
  def initialize(token)
    @token = token
  end

  def update_product(updated_product)
    uri = URI("#{BASE_URL}products/#{updated_product['SKU']}")

    request = Net::HTTP::Put.new(uri.path)
    request['Authorization'] = "Bearer #{@token}"
    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    request.body = updated_product.to_json

    response = connection.request(request)

    handle_response(response)
  end

  private

  def connection
    @connection ||= begin
      uri = URI(BASE_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 10
      http.start
      http
    end
  end

  def handle_response(response)
    raise StandardError, "API Error: #{response.code} - #{response.message}" unless response.is_a?(Net::HTTPSuccess)

    body = response.body
    return { 'status' => 'success' } if body.nil? || body.empty?

    JSON.parse(body)
  end
end
