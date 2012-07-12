require 'rspec'
require 'sndacs'

RSpec.configure do |config|
  config.include RSpec::Matchers

  config.mock_with :rspec
end

module Sndacs

  # Default configurations, see Sndacs::Config for more info
  Config.access_key_id = '7EDX20CJ54PA31INPXTD469MR'
  Config.secret_access_key = 'NzljZWE0MzgtNGQ0Yi00ZGZiLWI0YzMtOTQzODE2MTkzN2Nk'
  Config.host = 'storage.grandcloud.cn'
  Config.content_host = 'storage.sdcloud.cn'
  Config.proxy = nil 
  Config.timeout = 60
  Config.use_ssl = false
  Config.chunk_size = 104856
  Config.debug = false

end

