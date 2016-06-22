require "http/client"

{% if LibSSL::OPENSSL_102 %}
  puts "\n\nLibssl >= 1.0.2 was detected!\n\n\n"
{% else %}
  puts "\n\nLibssl >= 1.0.2 wasn't detected!\n\n\n"
{% end %}

pool_size   =   100
urls        =   File.read_lines("./data/https_urls.txt").map { |url| url.strip }
channel     =   Channel(Nil).new

group_index =   0

urls.each_slice(pool_size) do |url_group|
  #File.open("./data/groups/11/https_#{group_index}.txt", "w") do |f|
  #  f.print url_group.join("\n")
  #end
  
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
  
  group_index += 1
  
  url_group.size.times do
    channel.receive
  end
end

puts "#{Time.now}: Successfully fetched all HTTPS urls!"