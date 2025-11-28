require 'net/ftp'

class FtpDownloader
  def initialize(host, username, password)
    @host = host
    @username = username
    @password = password
  end

  def download_file(filename)
    Net::FTP.open(@host, @username, @password) do |ftp|
      ftp.getbinaryfile(filename, nil)
    end
  rescue Net::FTPError => e
    raise StandardError, "Failure to connect to ftp: #{e.message}"
  end
end
