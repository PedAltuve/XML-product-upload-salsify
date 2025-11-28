require 'minitest/autorun'
require_relative '../../services/xml_parser'

class XmlParserTest < Minitest::Test
  def setup
    @xml_content = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
          <products>
            <product Item_Name="Flolion Liquoroso ba UPDATED" SKU="12364911_42">
              <Brand>Salillina Adega UPDATED</Brand>
              <Color>BLUE</Color>
              <MSRP>9.99</MSRP>
              <Bottle_Size>750mL</Bottle_Size>
              <Alcohol_Volume>0.14</Alcohol_Volume>
              <Description>Flamboyantly UPDATED</Description>
            </product>
            <product Item_Name="Groblage Secco ba UPDATED" SKU="12364912_42">
              <Brand>Francinues Secco UPDATED</Brand>
              <MSRP>500</MSRP>
              <Description>Angular UPDATED</Description>
            </product>
          </products>
    XML

    @parser = XmlParser.new(@xml_content)
  end

  def test_parse_products_returns_array
    products = @parser.parse_products
    assert_kind_of Array, products
    assert_equal 2, products.length
  end

  def test_handles_empty_products_list
    xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <products>
      </products>
    XML

    parser = XmlParser.new(xml)
    products = parser.parse_products

    assert_equal 0, products.length
  end

  def test_handles_invalid_xml
    invalid_xml = '<products><product'

    parser = XmlParser.new(invalid_xml)

    error = assert_raises(StandardError) do
      parser.parse_products
    end

    assert_match(/Invalid XML/, error.message)
  end

  def test_parse_products_excludes_empty_fields
    products = @parser.parse_products
    second_product = products[1]

    assert_equal '12364912_42', second_product['SKU']
    assert_equal 'Groblage Secco ba UPDATED', second_product['Item Name']

    assert_equal 'Francinues Secco UPDATED', second_product['Brand']
    assert_equal '500', second_product['MSRP']
    assert_equal 'Angular UPDATED', second_product['Description']

    refute second_product.key?('Color')
    refute second_product.key?('Bottle Size')
    refute second_product.key?('Alcohol Volume')
  end
end
