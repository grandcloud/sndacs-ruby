module Sndacs

  module BucketsExtension
    # Builds new bucket with given name
    def build(name)
      Bucket.send(:new, proxy_owner, name)
    end

    # Finds the bucket with given name
    def find_first(name)
      bucket = build(name)

      bucket.retrieve
    rescue Error::NoSuchBucket, Error::ForbiddenBucket
      nil
    end
    alias :find :find_first

    # Finds all buckets in the service
    def find_all
      proxy_target
    end

    # Destroys all buckets in the service. Doesn't destroy non-empty
    # buckets by default, pass true to force destroy (USE WITH CARE!).
    def destroy_all(force = false)
      proxy_target.each { |bucket| bucket.destroy(force) }
    end
  end

end
