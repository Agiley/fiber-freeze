require "http/client"

200.times do
  spawn do
    puts "#{Time.now}: Fetching https://www.google.com"
    HTTP::Client.get("https://www.google.com")
  end
end

sleep 100