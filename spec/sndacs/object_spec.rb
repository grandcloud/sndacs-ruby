require 'net/http'
require 'spec_helper'

module Sndacs

    describe Object do
        before :all do
            @service = Sndacs::Service.new

            @bucket_spec_name = "bucket-spec-test-#{Time.now.to_i.to_s}"
            @bucket_spec_region = 'huabei-1'
            @bucket_spec = Bucket.send(:new, @service, @bucket_spec_name, @bucket_spec_region)
            @bucket_spec.save
        end

        after :all do
            @bucket_spec.destroy
        end

        before :each do
            #sleep 1

            @object_spec_name = "object-spec-test-#{Time.now.to_i.to_s}.txt"
            @object_spec_content = 'Hello,world!'
            @object_spec = @bucket_spec.object @object_spec_name
            @object_spec.content = @object_spec_content
        end

        context "#retrieve" do
            it "should works" do
                @object_spec.save

                object = @object_spec.retrieve
                object.should == @object_spec

                @object_spec.destroy
            end

            it "should raise Sndacs::Error::NoSuchKey if object does not exist" do
                lambda {
                    @object_spec.retrieve
                }.should raise_error(Sndacs::Error::NoSuchKey)
            end
        end

        context "#content" do
            before :each do
                @object_spec.save
            end

            after :each do
                @object_spec.destroy
            end

            it "should works" do
                object_content = @object_spec.content

                object_content.should == @object_spec_content
            end

            it "should reload content with force=true" do
                @object_spec.should_receive(:get_object).and_return(@object_spec_content)

                @object_spec.content(true)
            end
        end

        context "#save" do
            it "should works" do
                @object_spec.should_receive(:put_object).and_return(true)

                @object_spec.save
            end

            it "should update object's content when change its content and save" do
                new_content = 'Hello,sndacs!'

                @object_spec.content = new_content
                @object_spec.save

                object_content = @object_spec.content(true)
                object_content.should == new_content

                @object_spec.destroy
            end
        end

        context "#destroy" do
            before :each do
                @object_spec.save
            end

            it "should works" do
                @object_spec.destroy.should == true
            end

            it "should raise Sndacs::Error::NoSuchKey if object does not exist" do
                @object_spec.destroy.should == true

                lambda {
                    @object_spec.destroy
                }.should raise_error(Sndacs::Error::NoSuchKey)
            end
        end

        context "#url" do
            before :each do
                @object_spec.save
            end

            after :each do
                @object_spec.destroy
            end

            it "should works" do
                @object_spec.url.should =~ /#{@bucket_spec_name}\/#{@object_spec_name}/
            end
        end

        context "#cname_url" do
            before :each do
                @object_spec.save
            end

            after :each do
                @object_spec.destroy
            end

            xit "should works" do
                #@object_spec.url.should =~ /#{@bucket_spec_name}\/#{@object_spec_name}/
            end
        end

        context "#temporary_url" do
            before :each do
                @object_spec.save
            end

            after :each do
                @object_spec.destroy
            end

            it "should works" do
                object_url = @object_spec.temporary_url
                object_url.should =~ /#{@bucket_spec_name}\/#{@object_spec_name}/

                object_content = Net::HTTP.get(URI(object_url))
                object_content.should == @object_spec_content
            end
        end

        context "#exists?" do
            it "should return true if object exists" do
                @object_spec.save

                @object_spec.exists?.should == true

                @object_spec.destroy
            end

            it "should return false if object does not exist" do
                @object_spec.exists?.should == false
            end
        end
    end

end
