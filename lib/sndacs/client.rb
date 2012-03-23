module Sndacs
  class Client
    DEFAULT_OPTIONS = {
    }

    def initialize(access_key, access_secret, a, opts={})
      @access_key = access_key
      @access_secret = @access_secret
      @opts = DEFAULT_OPTIONS.merge(opts || {})
    end
  end
end
