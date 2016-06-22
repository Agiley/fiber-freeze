require "http/client"

pool_size   =   100
urls        =   File.read_lines("./data/https_urls.txt").map { |url| url.strip }
channel     =   Channel(Nil).new

urls.each_slice(pool_size) do |url_group|
  url_group.each do |url|
    spawn do
      puts "#{Time.now}: Fetching #{url}..."
      
      uri             =   URI.parse(url)
      path            =   uri.path.try &.empty? ? "/" : uri.path.as(String)
      
      http_client     =   HTTP::Client.new(uri).tap do |c|
        c.connect_timeout   =   5.seconds
        c.dns_timeout       =   5.seconds
        c.read_timeout      =   15.seconds
      end
      
      begin
        response      =   http_client.get(path, headers: HTTP::Headers{ "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36" })
        puts "#{Time.now}: Status code for url #{url} was #{response.try &.status_code}..."
        
      rescue
        puts "#{Time.now}: Error occurred. Proceeding..."
      
      ensure
        http_client.close rescue nil
      end
      
      channel.send(nil)
    end
  end
  
  url_group.size.times do
    channel.receive
  end
end

puts "#{Time.now}: Successfully fetched all HTTPS urls!"