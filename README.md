# fiber_freeze

Crystal freezes when fetching http / https urls using fibers.

The exact same error occurs when using [fiberpool](https://github.com/akitaonrails/fiberpool]) and [Sidekiq.cr](https://github.com/mperham/sidekiq.cr])

## Usage / Reproducing
    $ git clone git://github.com/Agiley/fiber-freeze.git
    $ cd fiber-freeze
    $ crystal deps

Fetch https urls using fibers (freezes/hangs after a few minutes):

    $ crystal examples/https_with_fibers.cr 

Fetch http urls using fibers (freezes/hangs after a few minutes):

    $ crystal examples/http_with_fibers.cr 
