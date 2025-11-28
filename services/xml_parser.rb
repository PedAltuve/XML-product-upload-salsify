require 'nokogiri'

class XmlParser
  def initialize(xml_content)
    @doc = Nokogiri::XML(xml_content)
  end

  def parse_products
    products = []

    raise StandardError, "Invalid XML: #{@doc.errors.join(', ')}" if @doc.errors.any?

    @doc.xpath('//product').each do |product|
      products << parse_product(product)
    end

    products
  end

  private

  def parse_product(product_node)
    product = {
      'SKU' => product_node['SKU'] || '',
      'Item Name' => product_node['Item_Name'] || ''
    }

    add_if_present(product, product_node, 'Brand')
    add_if_present(product, product_node, 'Color')
    add_if_present(product, product_node, 'MSRP')
    add_if_present(product, product_node, 'Bottle Size', 'Bottle_Size')
    add_if_present(product, product_node, 'Alcohol Volume', 'Alcohol_Volume')
    add_if_present(product, product_node, 'Description')

    product
  end

  def add_if_present(product_hash, node, key, xpath_name = nil)
    xpath_name ||= key.gsub(' ', '_')
    value = extract_text(node, xpath_name)
    product_hash[key] = value unless value.empty?
  end

  def extract_text(node, element_name)
    element = node.at_xpath(element_name)
    element&.text&.strip || ''
  end
end
