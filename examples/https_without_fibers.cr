require "../src/fiber_freeze"

client = FiberFreeze::Client.new(protocol: "https", use_fibers: false)
client.crawl