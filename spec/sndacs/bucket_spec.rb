require 'spec_helper'

module Sndacs

    describe Bucket do
        before :all do
            @service = Sndacs::Service.new
        end

        before :each do
            sleep 1  # for delay

            @bucket_spec_name = 'bucket-spec-test-' << Time.now.to_i.to_s
            @bucket_spec_region = 'huabei-1'
            @bucket_spec = Bucket.send(:new, @service, @bucket_spec_name, @bucket_spec_region)
        end

        context "#retrieve" do
            it "should works" do
                @bucket_spec.save

                bucket = @bucket_spec.retrieve
                bucket.should == @bucket_spec

                @bucket_spec.destroy
            end

            it "should raise Sndacs::Error::NoSuchBucket if bucket does not exist" do
                lambda {
                    @bucket_spec.retrieve
                }.should raise_error(Sndacs::Error::NoSuchBucket)
            end
        end

        context "#location" do
            before :each do
                @bucket_spec.save
            end

            after :each do
                @bucket_spec.destroy
            end

            it "should works" do
                bucket_location = @bucket_spec.location

                bucket_location.should == @bucket_spec_region
            end

            it "should reload location with force=true" do
                @bucket_spec.should_receive(:location_constraint).and_return(@bucket_spec_region)

                @bucket_spec.location(true)
            end
        end

        context "#save" do
            it "should works" do
                @bucket_spec.should_receive(:create_bucket_configuration)

                @bucket_spec.save
            end

            it "should raise Sndacs::Error::BucketAlreadyExists if bucket alreay exist" do
                @bucket_spec.save

                lambda {
                    @bucket_spec.save
                }.should raise_error(Sndacs::Error::BucketAlreadyExists)

                @bucket_spec.destroy
            end
        end

        context "#destroy" do
            before :each do
                @bucket_spec.save
            end

            it "should works" do
                #@bucket_spec.should_receive(:delete_bucket)

                @bucket_spec.destroy.should == true
            end

            it "should destroy bucket whether it has objects in it with force=true" do
                bucket_object = @bucket_spec.object("object-spec-test-#{Time.now.to_i.to_s}")
                bucket_object.content = 'Hello,world!'
                bucket_object.save

                @bucket_spec.destroy(true).should == true
            end

            it "should raise Sndacs::Error::NoSuchBucket if bucket doest not exist" do
                @bucket_spec.destroy

                lambda {
                    @bucket_spec.destroy
                }.should raise_error(Sndacs::Error::NoSuchBucket)
            end

            it "should raise Sndacs::Error::BucketNotEmpty if bucket has objects in it" do
                bucket_object = @bucket_spec.object("object-spec-test-#{Time.now.to_i.to_s}")
                bucket_object.content = 'Hello,world!'
                bucket_object.save

                lambda {
                    @bucket_spec.destroy
                }.should raise_error(Sndacs::Error::BucketNotEmpty)

                bucket_object.destroy

                @bucket_spec.destroy
            end
        end

        context "#exists?" do
            it "should return true if bucket exists" do
                @bucket_spec.save

                @bucket_spec.exists?.should == true

                @bucket_spec.destroy
            end

            it "should return false if bucket does not exist" do
                @bucket_spec.exists?.should == false
            end
        end

        context "#vhost?" do
            xit "should works" do
            end
        end

        context "#host" do
            it "should obey @location when @location is supplied" do
                @bucket_spec.host.should =~ /#{@bucket_spec_region}/
            end

            it "should use Sndacs::REGION_DEFAULT when @location is empty" do
                bucket_tmp = Bucket.send(:new, @service, @bucket_spec_name, nil)
                bucket_tmp.host.should =~ /#{Sndacs::REGION_DEFAULT}/
            end
        end

        context "#path_prefix" do
            it "should works" do
                @bucket_spec.path_prefix.should =~ /#{@bucket_spec_name}/
            end
        end

        context "#objects" do
            before :each do
                @bucket_spec.save
            end

            after :each do
                @bucket_spec.destroy true
            end

            it "should works" do
                bucket_object = @bucket_spec.object("object-spec-test-#{Time.now.to_i.to_s}")
                bucket_object.content = 'Hello,world!'
                bucket_object.save

                bucket_objects = @bucket_spec.objects
                bucket_objects.should be_instance_of(Array)
                bucket_objects.should include(bucket_object)
            end
        end

        context "#object" do
            it "should works" do
                @bucket_spec.object("object-spec-test-#{Time.now.to_i.to_s}").should be_instance_of(Sndacs::Object)
            end
        end
    end

end
