require "../src/fiber_freeze"

client = FiberFreeze::Client.new(protocol: "http", use_fibers: true)
client.crawl