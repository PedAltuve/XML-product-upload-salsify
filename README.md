# XML Product Upload to Salsify

A Ruby application that downloads product data from an FTP server,
parses XML content and uploads the products to the Salsify API.

## How it works

The script uses three services in sequence:

### FTP Download (services/ftp_downloader.rb)

- Connects to an FTP server using credentials from environment variables
- Downloads the specified XML file (products.xml) using binary transfer mode
- Returns the contents as a string

### XML Parsing (services/xml_parser.rb)

- Parses the XML content using Nokogiri
- Extracts product data from <product> nodes
- Maps XML attributes and child elements to hash keys matching Salsify's API format
- Only includes fields that have values to prevent API validation errors
- Returns an array of product hashes

### API Upload (services/api_client.rb)

- Sends HTTP PUT request to Salsify API using Ruby's Net::HTTP
- Authenticates using Bearer token from environment variables
- Raises descriptive errors for failed API calls (4xx, 5xx)

### Main (main.rb)

- Validates all required environment variables on startup
- Coordinates the three services in sequence
- Provides progress output to the console
- Returns non-zero exit code on fatal errors for CI/CD integration

## Documentation used

- Perplexity and google to search for an XML gem.
- [Faraday's documentation] (<https://lostisland.github.io/faraday/#/middleware/included/authentication>)
- [Nokogiri's documentation] (<https://nokogiri.org/index.html>)
- [Net::FTP documentation] (<https://ruby-doc.org/3.4.1/gems/net-ftp/Net/FTP.html#method-i-getbinaryfile>)
- [Net::HTTP documentation] (<https://ruby-doc.org/core-3.1.2/Net/HTTP.html>)

## Architecture decisions

### Why Net::HTTP instead of X gem?

Initially tried to use Faraday, but switched to Net::HTTP because:

- Faraday's authentication middleware was causing 302 redirects
- One less gem to manage

### Why Nokogiri and not something else?

It had very good reputation, active development and seemed like it would
process the XML without any issues

## Setup Instructions

### 1. Install Dependencies

```bash
bundle install

```

### 2. Configure Environment Variables

Copy the example environment file and fill in your credentials:

```bash
cp .env.example .env
```

Edit .env with your actual values:

```
FTP_HOST=ftp.yourserver.com
FTP_USERNAME=your_username
FTP_PASSWORD=your_password
XML_FILENAME=products.xml
SALSIFY_API_TOKEN=your_salsify_api_token
```

### 3. Run the Script

```bash
ruby main.rb
```

### 4. Run Tests

Run all tests

```bash
ruby -Ilib:test tests/services/ftp_downloader_test.rb
ruby -Ilib:test tests/services/xml_parser_test.rb
ruby -Ilib:test tests/services/api_client_test.rb
ruby -Ilib:test tests/main_test.rb
```

Or run a single test file

```bash
ruby -Ilib:test tests/main_test.rb
```

## Expected Output

```
Downloading XML file from FTP
File downloaded successfully!
Parsing XML content
Found 4 products
Uploading products to Salsify API
Updated product 12364911_42
Updated product 12364912_42
Updated product 12364913_42
Updated product 12364914_42
All products have been updated successfully!
```

If errors occur:

```
Downloading XML file from FTP
File downloaded successfully!
Parsing XML content
Found 4 products
Uploading products to Salsify API
Updated product 12364911_42
Failed to update product 12364912_42: API Error: 422 - Unprocessable Entity
Updated product 12364913_42
Updated product 12364914_42
All products have been updated successfully!
```

## Third-Party Libraries

### nokogiri (~> 1.18)

• Purpose: XML parsing with XPath support
• Why chosen:
 • Industry standard for XML/HTML parsing in Ruby
 • Robust error handling and validation
 • XPath support makes node selection simple and readable
• Alternatives considered:
 • Ox (fast but less feature-rich)

### dotenv (~> 3.1)

• Purpose: Load environment variables from .env file
• Why chosen:
 • De facto standard for managing environment configuration in Ruby
 • Prevents hardcoding credentials in source code
 • Simple, zero-configuration setup
• Alternatives considered:
 • Manual ENV loading (more error-prone)

### net/http (Ruby stdlib)

• Purpose: HTTP client for Salsify API requests
• Why chosen:
 • Built into Ruby (no external dependency)
 • Direct control over request/response handling
 • Sufficient for simple REST API calls
 • Better debugging than abstraction layers
• Alternatives considered:
 • Faraday (caused authentication issues with Bearer tokens)

### net/ftp (Ruby stdlib)

• Purpose: FTP client for downloading XML files
• Why chosen:
 • Built into Ruby (no external dependency)
 • Simple interface for basic FTP operations
 • Binary transfer mode support
• Alternatives considered:
 • None - FTP is the required protocol per spec

### minitest (Ruby stdlib)

• Purpose: Testing framework
• Why chosen:
 • Built into Ruby (no external dependency)
 • Simple, readable test syntax
 • Powerful mocking capabilities
 • Fast test execution
• Alternatives considered:
 • None

## How long did I spend on this exercise?

It took me about an hour to get the services working with their tests,
then I began having issues with Faraday in the main file.

So it took me about 30 more minutes to debug, ditch Faraday and start over,
and update the tests.

And finally, about 20 minutes to write the README

All in all, close to 2 hours overall.

## What would I add if I had unlimited/more time?

### Structure agnostic XML parser

The parser is currently coupled to the specific XML structure,
I would add a configuration-driven parser using a mapping file (YAML/JSON),
this would make it reusable across different data sources

### Enhanced CLI capabilities

I would like to add command-line argument parsing to allow for specific files,
environments, SKUs or format options

### Proper logging

Replace puts with a proper logger that supports log levels, file output, etc

### Retry logic

In case there are API failures, some retry logic could be useful

### Webhook notifications

Alert on completion/failure (Slack, email, PagerDuty)

## If I were to critique my code, what would I say?

After looking at it with reviewer eyes, I'd say there are a couple of things that can
be easily fixed and make it a bit better overall:

- Timeout numbers can be configurable via ENV variables
- FTP Downloader has a very generic error,
it could be more specific to what Net::FTPError raises
- The Salsify API client should have rate limit handling since it's coming in the headers
