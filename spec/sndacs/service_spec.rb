require 'spec_helper'

require 'sndacs/service'

module Sndacs
  describe Service do
    context "#buckets" do
      context "when buckets is empty" do
        it "should works" do
          @service_empty_buckets_list = Sndacs::Service.new(
            :access_key_id =>  "12345678901234567890",
            :secret_access_key =>  "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDF"
          )
          @response_empty_buckets_list = Net::HTTPOK.new("1.1", "200", "OK")
          @service_empty_buckets_list.should_receive(:service_request).and_return(@response_empty_buckets_list)
          @response_empty_buckets_list.should_receive(:body).and_return(@buckets_empty_list_body)
          @buckets_empty_list_body = <<-EOEmptyBuckets
    <?xml version="1.0" encoding="UTF-8"?>\n<ListAllMyBucketsResult xmlns="http://storage.grandcloud.cn/doc/2006-03-01/"> <Owner> <ID>123u1odhkhfoadf</ID> <DisplayName>JohnDoe</DisplayName> </Owner> <Buckets> </Buckets> </ListAllMyBucketsResult>
          EOEmptyBuckets
          @service_empty_buckets_list.buckets.should == []
        end
      end
    end
  end
end
