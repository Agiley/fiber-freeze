require "../src/fiber_freeze"

client = FiberFreeze::Client.new(protocol: "http", use_fibers: false)
client.crawl