require 'dotenv/load'
require_relative 'services/api_client'
require_relative 'services/ftp_downloader'
require_relative 'services/xml_parser'

class ProductUploadService
  def initialize
    @ftp_host = ENV['FTP_HOST']
    @ftp_username = ENV['FTP_USERNAME']
    @ftp_password = ENV['FTP_PASSWORD']
    @ftp_filename = ENV['XML_FILENAME']
    @salsify_token = ENV['SALSIFY_API_TOKEN']

    validate_environment_variables
  end

  def run
    puts 'Downloading XML file from FTP'
    xml_content = download_xml
    puts 'File downloaded successfully!'

    puts 'Parsing XML content'
    products = parse_xml(xml_content)
    puts "Found #{products.length} products"

    puts 'Uploading products to Salsify API'
    upload_products(products)
    puts 'All products have been updated successfully!'
  rescue StandardError => e
    puts "Error: #{e.message}"
    exit 1
  end

  private

  def validate_environment_variables
    required_vars = %w[FTP_HOST FTP_USERNAME FTP_PASSWORD XML_FILENAME SALSIFY_API_TOKEN]
    missing_vars = required_vars.select { |var| ENV[var].nil? || ENV[var].empty? }

    return if missing_vars.empty?

    raise "Missing required environment variables: #{missing_vars.join(', ')}"
  end

  def download_xml
    downloader = FtpDownloader.new(@ftp_host, @ftp_username, @ftp_password)
    downloader.download_file(@ftp_filename)
  end

  def parse_xml(xml_content)
    parser = XmlParser.new(xml_content)
    parser.parse_products
  end

  def upload_products(products)
    api_client = SalsifyApiClient.new(@salsify_token)
    products.each do |product|
      api_client.update_product(product)
      puts "Updated product #{product['SKU']}"
    rescue StandardError => e
      puts "Failed to update product #{product['SKU']}: #{e.message}"
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  service = ProductUploadService.new
  service.run
end
