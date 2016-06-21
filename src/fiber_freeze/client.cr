require "fiberpool"
require "http/client"
require "xml"

module FiberFreeze
  class Client
    @queue    =   Set(String).new
    @crawled  =   Set(String).new
    @mutex    =   Mutex.new
    
    def initialize(@protocol = "https", @use_fibers = true, @pool_size = 50)
      @queue.merge(File.read_lines("./data/#{protocol}_urls.txt").map { |url| url.strip })
    end
    
    def crawl
      output_macro_status
      
      while !@queue.empty?
        puts "\n@queue size: #{@queue.size}\n\n\n"
        
        if @use_fibers
          pool = Fiberpool.new(@queue, @pool_size)
          pool.run do |url|
            crawl_url(url)
          end
        else
          @queue.each do |url|
            crawl_url(url)
          end
        end
      end
    end
    
    def output_macro_status
      {% if LibSSL::OPENSSL_102 %}
        puts "\n\nLibssl >= 1.0.2 was detected!\n\n\n"
      {% else %}
        puts "\n\nLibssl >= 1.0.2 wasn't detected!\n\n\n"
      {% end %}
    end
    
    def crawl_url(url)
      @mutex.synchronize do
        @crawled.add(url)
        @queue.delete(url)
      end
      
      parsed          =   get_response(url)
      
      links           =   parsed ? parsed.xpath("//a").as(XML::NodeSet | Nil) : nil
      
      links.each do |link|
        href          =   link["href"]?
        
        if href && absolute_url?(href) && using_desired_procotol?(href)
          @mutex.synchronize do
            @queue.add(href) unless @crawled.includes?(href)
          end
        end
      end if links && links.any?
    end
    
    def absolute_url?(url)
      !(url =~ /^http(s)?:\/\//i).nil?
    end
    
    def using_desired_procotol?(url) : Bool
      uri               =   URI.parse(url)
      (uri.try &.scheme == @protocol)
    end
    
    def get_response(url, redirect_limit = 5)
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
      
          case response.status_code
            when 301
              redirect_limit -= 1
              parsed    =   get_response(response.headers["Location"], redirect_limit) if response.headers["Location"]? && redirect_limit > 0
            when 200
              parsed    =   XML.parse_html(response.body)
          end
      
        rescue
          puts "#{Time.now}: Error occurred. Proceeding..."
        
        ensure
          http_client.close
        end
      end
      
      return parsed
    end
    
  end
end
