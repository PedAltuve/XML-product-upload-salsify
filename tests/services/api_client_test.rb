require 'minitest/autorun'
require 'minitest/mock'
require_relative '../../services/api_client'

class SalsifyApiClientTest < Minitest::Test
  def setup
    @token = 'fake_token'
    @service = SalsifyApiClient.new(@token)

    @payload = {
      "SKU": '1234',
      "Item Name": 'XYZ Name',
      "Brand": 'Generic Wine Co.',
      "Color": 'red',
      "MSRP": '9.99',
      "Bottle Size": '750mL',
      "Alcohol Volume": '0.14',
      "Description": 'Example description.'
    }
  end

  def test_update_product_with_json_response
    response_body = '{"status": "updated"}'

    with_mocked_request(response_body: response_body) do
      result = @service.update_product(@payload)
      assert_equal({ 'status' => 'updated' }, result)
    end
  end

  private

  def with_mocked_request(response_body: '{}', success: true, code: '200', message: 'OK', &block)
    mock_response = create_mock_response(response_body, success, code, message)
    mock_request = create_mock_request
    mock_http = create_mock_http(mock_request, mock_response)

    Net::HTTP::Put.stub :new, mock_request do
      Net::HTTP.stub :new, mock_http, &block
    end

    mock_request.verify
    mock_response.verify
  end

  def create_mock_response(body, success, code, message)
    mock = Minitest::Mock.new
    mock.expect :is_a?, success, [Net::HTTPSuccess]

    if success
      mock.expect :body, body
    else
      mock.expect :code, code
      mock.expect :message, message
    end

    mock
  end

  def create_mock_request
    mock = Minitest::Mock.new
    mock.expect :[]=, nil, ['Authorization', "Bearer #{@token}"]
    mock.expect :[]=, nil, ['Content-Type', 'application/json']
    mock.expect :[]=, nil, ['Accept', 'application/json']
    mock.expect :body=, nil, [String]
    mock
  end

  def create_mock_http(mock_request, mock_response)
    mock = Minitest::Mock.new
    mock.expect :start, nil
    mock.expect :use_ssl=, nil, [true]
    mock.expect :open_timeout=, nil, [5]
    mock.expect :read_timeout=, nil, [10]
    mock.expect :request, mock_response, [mock_request]
    mock
  end
end
