require 'rspec'
require 'sndacs'

RSpec.configure do |config|
  config.include RSpec::Matchers

  config.mock_with :rspec
end

module Sndacs

  # Default configurations, see Sndacs::Config for more info
  Config.access_key_id = 'yourkey'
  Config.secret_access_key = 'yoursecret'
  Config.host = 'storage.grandcloud.cn'
  Config.content_host = 'storage.sdcloud.cn'
  Config.proxy = nil 
  Config.timeout = 60
  Config.use_ssl = false
  Config.chunk_size = 104856
  Config.debug = false

end

