require 'spec_helper'

require 'sndacs/client'

module Sndacs
  describe Client do
    subject { Client.new "access key", "access secret" }
    it { should_not be_nil }
  end
end
