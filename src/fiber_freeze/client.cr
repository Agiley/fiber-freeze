require "http/client"
require "xml"

module FiberFreeze
  class Client
    @queue    =   Set(String).new
    
    def initialize(@protocol = "https", @use_fibers = true, @pool_size = 100)
      @queue.merge(File.read_lines("./data/#{@protocol}_urls.txt").map { |url| url.strip })
      #File.delete("./data/#{@protocol}_urls.txt") if File.exists?("./data/#{@protocol}_urls.txt")
    end
    
    def crawl
      output_macro_status
      
      urls            =   Set(String).new
      
      #dump_urls(@queue)
      
      if @use_fibers
        crawled       =   crawl_using_fibers(@queue)
        urls.merge(crawled)
        
        #dump_urls(crawled)
      else
        @queue.each do |url|
          crawled     =   crawl_url(url)
          urls.merge(crawled)
          
          #dump_urls(crawled)
        end
      end
    end
    
    private def crawl_using_fibers(queue, pool_size = @pool_size)
      urls            =   Set(String).new
      channel         =   Channel(Set(String)).new
      
      queue.each_slice(pool_size) do |queue_group|
        queue_group.each do |url|
          spawn do
            channel.send(crawl_url(url))
          end
        end
        
        queue_group.size.times do
          received    =   channel.receive
          urls.merge(received) if received && received.any?
        end
      end
      
      return urls
    end
    
    private def crawl_url(url)
      urls            =   Set(String).new
      
      parsed          =   get_response(url)
      
      links           =   parsed ? parsed.xpath("//a").as(XML::NodeSet | Nil) : nil
      
      links.each do |link|
        href          =   link["href"]?
        
        if href && absolute_url?(href) && crawlable?(href) && using_desired_procotol?(href)
          urls.add(href)
        end
      end if links && links.any?
      
      return urls
    end
    
    private def dump_urls(urls)
      File.open("./data/#{@protocol}_urls.txt", "a") do |f|
        f.print urls.join("\n")
      end
    end
    
    private def output_macro_status
      {% if LibSSL::OPENSSL_102 %}
        puts "\n\nLibssl >= 1.0.2 was detected!\n\n\n"
      {% else %}
        puts "\n\nLibssl >= 1.0.2 wasn't detected!\n\n\n"
      {% end %}
    end
    
    private def absolute_url?(url)
      !(url =~ /^http(s)?:\/\//i).nil?
    end
    
    private def crawlable?(url)
      (url =~ /\.(css|js|ico|bmp|gif|jpg|jpeg|png|psd|psp|pspimage|thm|tif|yuv|avi|mpg|mpeg|mkv|wmv|flv|mp4|asf|mp3|wav|ogg|doc|docx|pdf|ppt|ppx|zip|tar|tar\.gz|tar\.bz|gz|rar|bz).*$/i).nil?
    end
    
    private def using_desired_procotol?(url) : Bool
      uri               =   URI.parse(url)
      (uri.try &.scheme == @protocol)
    end
    
    private def get_response(url)
      parsed            =   nil
      
      if using_desired_procotol?(url)    
        puts "#{Time.now}: Fetching #{url} #{@use_fibers ? "using" : "without using"} fibers..."
        
        uri             =   URI.parse(url)
        path            =   uri.path.try &.empty? ? "/" : uri.path.as(String)
        
        headers         =   HTTP::Headers{ "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36" }
        
        http_client     =   HTTP::Client.new(uri).tap do |c|
          c.connect_timeout   =   5.seconds
          c.dns_timeout       =   5.seconds
          c.read_timeout      =   15.seconds
        end
        
        begin
          response      =   http_client.get(path, headers: headers)
          parsed        =   response.status_code == 200 ? XML.parse_html(response.body) : nil
      
        rescue
          puts "#{Time.now}: Error occurred. Proceeding..."
        
        ensure
          http_client.close rescue nil
        end
      end
      
      return parsed
    end
    
  end
end
