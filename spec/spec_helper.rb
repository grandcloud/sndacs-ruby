require 'rspec'

RSpec.configure do |config|
  config.include RSpec::Matchers

  config.mock_with :rspec
end
