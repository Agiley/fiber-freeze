require "http/client"

class Zlib::Inflate
  def read(slice : Slice(UInt8))
    check_open

    while true
      if @stream.avail_in == 0
        @stream.next_in = @buf.to_unsafe
        @stream.avail_in = @input.read(@buf.to_slice).to_u32
        return 0 if @stream.avail_in == 0
      end

      @stream.avail_out = slice.size.to_u32
      @stream.next_out = slice.to_unsafe

      ret = LibZ.inflate(pointerof(@stream), LibZ::Flush::NO_FLUSH)
      read_bytes = slice.size - @stream.avail_out
      case ret
      when LibZ::Error::NEED_DICT,
           LibZ::Error::DATA_ERROR,
           LibZ::Error::MEM_ERROR
        raise Zlib::Error.new(ret, @stream)
      when LibZ::Error::STREAM_END
        return read_bytes
      else
        # LibZ.inflate might not write any data to the output slice because
        # it might need more input. We can know this happened because `ret`
        # is not STREAM_END.
        if read_bytes == 0
          next
        else
          return read_bytes
        end
      end
    end
  end
end

{% if LibSSL::OPENSSL_102 %}
  puts "\n\nLibssl >= 1.0.2 was detected!\n\n\n"
{% else %}
  puts "\n\nLibssl >= 1.0.2 wasn't detected!\n\n\n"
{% end %}

pool_size   =   100
urls        =   File.read_lines("./data/groups/https_11.txt").map { |url| url.strip }
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