require 'spec_helper'
require 'sndacs/service'

module Sndacs

    describe Service do
        context "#buckets" do
            context "when buckets is empty" do
                before :each do
                    @service_empty = Sndacs::Service.new
                    @response_empty = Net::HTTPOK.new('1.1', '200', 'OK')
                    @buckets_empty_body = <<-EOEmptyBuckets
<?xml version="1.0" encoding="UTF-8"?>\n<ListAllMyBucketsResult xmlns="http://storage.grandcloud.cn/doc/2006-03-01/"><Owner><ID>123u1odhkhfoadf</ID> <DisplayName>JohnDoe</DisplayName></Owner><Buckets></Buckets></ListAllMyBucketsResult>
                    EOEmptyBuckets
                end

                it "should works" do
                    @service_empty.should_receive(:service_request).and_return(@response_empty)
                    @response_empty.should_receive(:body).and_return(@buckets_empty_body)

                    @service_empty.buckets.should == []
                end
            end

            context "when buckets is not empty" do
                before :each do
                    @service = Sndacs::Service.new
                end

                it "should works" do
                    @service.buckets.should be_instance_of(Array)
                end
            end
        end
    end

end
