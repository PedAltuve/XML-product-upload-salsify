require 'minitest/autorun'
require 'minitest/mock'
require_relative '../../services/ftp_downloader'

class FtpDownloaderTest < Minitest::Test
  def setup
    @host = 'ftp.test.com'
    @username = 'user'
    @password = 'password'
    @filename = 'inventory.xml'
    @downloader = FtpDownloader.new(@host, @username, @password)
  end

  def test_download_success
    mock_ftp = Minitest::Mock.new
    mock_ftp.expect :getbinaryfile, 'fake_xml_content', [@filename, nil]

    fake_open = lambda { |host, username, password, &block|
      raise 'Wrong credentials used' unless host == @host && username == @username && password == @password

      block.call(mock_ftp)
    }

    Net::FTP.stub :open, fake_open do
      result = @downloader.download_file(@filename)

      assert_equal 'fake_xml_content', result
    end
  end

  def test_download_failure
    bad_open = lambda { |host, username, password, &block|
      raise Net::FTPError, 'Connection refused'
    }

    Net::FTP.stub :open, bad_open do
      assert_raises(StandardError) do
        @downloader.download_file(@filename)
      end
    end
  end
end
