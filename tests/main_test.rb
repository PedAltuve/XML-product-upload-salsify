require 'minitest/autorun'
require 'minitest/mock'
require_relative '../main'

class ProductUploadServiceTest < Minitest::Test
  def setup
    set_env_vars
  end

  def teardown
    clear_env_vars
  end

  def test_successful_upload_with_three_products
    with_mocked_services(xml: valid_xml(3), products: 3) do
      service = ProductUploadService.new
      assert_output(/Found 3 products/) { service.run }
    end
  end

  def test_successful_upload_with_zero_products
    with_mocked_services(xml: empty_xml, products: 0) do
      service = ProductUploadService.new
      assert_output(/Found 0 products/) { service.run }
    end
  end

  def test_partial_failure_one_product_fails
    mock_api_client = failing_api_client(fail_on: 2)

    with_mocked_services(xml: valid_xml(3), api_client: mock_api_client) do
      service = ProductUploadService.new
      assert_output(/Updated product.*Failed to update product.*Updated product/m) do
        service.run
      end
    end
  end

  def test_all_products_fail_api_update
    mock_api_client = failing_api_client(fail_on: :all)

    with_mocked_services(xml: valid_xml(3), api_client: mock_api_client) do
      service = ProductUploadService.new
      output = capture_io { service.run }

      assert_match(/Failed to update product SKU001/, output[0])
      assert_match(/Failed to update product SKU002/, output[0])
      assert_match(/Failed to update product SKU003/, output[0])
    end
  end

  def test_missing_environment_variable
    ENV.delete('SALSIFY_API_TOKEN')

    error = assert_raises(RuntimeError) { ProductUploadService.new }
    assert_match(/Missing required environment variables: SALSIFY_API_TOKEN/, error.message)
  end

  private

  def set_env_vars
    ENV['FTP_HOST'] = 'ftp.test.com'
    ENV['FTP_USERNAME'] = 'testuser'
    ENV['FTP_PASSWORD'] = 'testpass'
    ENV['XML_FILENAME'] = 'products.xml'
    ENV['SALSIFY_API_TOKEN'] = 'test_token_123'
  end

  def clear_env_vars
    %w[FTP_HOST FTP_USERNAME FTP_PASSWORD XML_FILENAME SALSIFY_API_TOKEN].each do |var|
      ENV.delete(var)
    end
  end

  def with_mocked_services(xml:, products: nil, api_client: nil, &block)
    mock_downloader = Minitest::Mock.new
    mock_downloader.expect :download_file, xml, [String]

    mock_api_client = api_client || create_successful_api_client(products)

    FtpDownloader.stub :new, ->(*_args) { mock_downloader } do
      SalsifyApiClient.stub :new, ->(*_args) { mock_api_client }, &block
    end

    mock_downloader.verify
    mock_api_client.verify if mock_api_client.respond_to?(:verify)
  end

  def create_successful_api_client(count)
    return Minitest::Mock.new if count.zero?

    mock = Minitest::Mock.new
    count.times { mock.expect :update_product, { 'status' => 'success' }, [Hash] }
    mock
  end

  def failing_api_client(fail_on:)
    call_count = 0

    Object.new.tap do |obj|
      obj.define_singleton_method(:update_product) do |_product|
        call_count += 1

        raise StandardError, 'API Error: 500' if fail_on == :all || call_count == fail_on

        { 'status' => 'success' }
      end
    end
  end

  def valid_xml(product_count)
    products = (1..product_count).map do |i|
      <<~PRODUCT
        <product Item_Name="Product #{i}" SKU="SKU00#{i}">
          <Brand>Brand #{('A'.ord + i - 1).chr}</Brand>
          <Color>red</Color>
          <MSRP>#{10 * i}.00</MSRP>
          <Bottle_Size>750mL</Bottle_Size>
          <Alcohol_Volume>0.1#{i}</Alcohol_Volume>
          <Description>Product #{i} description</Description>
        </product>
      PRODUCT
    end

    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <products>
        #{products.join("\n")}
      </products>
    XML
  end

  def empty_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <products>
      </products>
    XML
  end
end
