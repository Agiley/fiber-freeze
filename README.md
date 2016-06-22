# fiber_freeze

Crystal freezes when fetching https urls using fibers.

The exact same error occurs when using [fiberpool](https://github.com/akitaonrails/fiberpool]) and [Sidekiq.cr](https://github.com/mperham/sidekiq.cr])

## Usage / Reproducing
    $ git clone git://github.com/Agiley/fiber-freeze.git && cd fiber-freeze

Fetch https urls using a minimal example (Crystal freezes/hangs after a few minutes):

    $ crystal examples/simple_https_with_fibers.cr

Fetch https urls using fibers (freezes/hangs after a few minutes):

    $ crystal examples/https_with_fibers.cr 

Fetch http urls using fibers (works):

    $ crystal examples/http_with_fibers.cr 
