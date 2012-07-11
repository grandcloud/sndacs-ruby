module Sndacs

  class Bucket
    include Parser
    include Proxies
    extend Forwardable

    attr_reader :name, :location, :service

    def_instance_delegators :service, :service_request
    private_class_method :new

    # Compares the bucket with other bucket. Returns true if the names
    # of the buckets are the same, and both have the same locations and services
    # (see Service equality)
    def ==(other)
      self.name == other.name and self.location == other.location and self.service == other.service
    end

    # Retrieves the bucket information from the server. Raises an
    # Sndacs::Error exception if the bucket doesn't exist or you don't
    # have access to it, etc.
    def retrieve
      bucket_headers

      self
    end

    # Returns location of the bucket, e.g. "huabei-1"
    def location(reload = false)
      return @location if defined?(@location) and not reload

      @location = location_constraint
    end

    # Saves the newly built bucket. Raises Sndacs::Error::BucketAlreadyExists
    # exception if the bucket already exists.
    #
    # ==== Options
    # * <tt>:location</tt> - location of the bucket
    #   (<tt>huabei-1</tt> or <tt>huadong-1</tt>)
    # * Any other options are passed through to
    #   Connection#request
    def save(options = {})
      if options
        if options.is_a?(String) && options.strip != ''
          options = {:location => options.strip}
        end

        if options.is_a?(Hash) && !options.has_key?(:location)
          options.merge!(:location => @location)
        end
      else
        options = {:location => @location}
      end

      create_bucket_configuration(options)

      true
    end

    # Destroys given bucket. Raises an Sndacs::Error::BucketNotEmpty
    # exception if the bucket is not empty. You can destroy non-empty
    # bucket passing true (to force destroy)
    def destroy(force = false)
      delete_bucket

      true
    rescue Error::BucketNotEmpty
      if force
        objects.destroy_all

        retry
      else
        raise
      end
    end

    # Similar to retrieve, but catches Sndacs::Error::NoSuchBucket
    # exceptions and returns false instead.
    def exists?
      retrieve

      true
    rescue Error::NoSuchBucket
      false
    end

    # Returns true if the name of the bucket can be used like +VHOST+
    # name. If the bucket contains characters like underscore it can't
    # be used as +VHOST+ (e.g. <tt>bucket_name.storage.grandcloud.cn</tt>)
    def vhost?
      #"#@name.#{Sndacs::Config.host}" =~ /\A#{URI::REGEXP::PATTERN::HOSTNAME}\Z/
      false
    end

    # Returns host name of the bucket according (see #vhost? method)
    def host(user_content = false)
      if user_content
        region_host = Sndacs::Config.content_host
        if @location
          region_host = Sndacs::CONTENT_HOST % @location
        end
      else
        region_host = Sndacs::Config.host
        if @location
          region_host = Sndacs::REGION_HOST % @location
        end
      end

      vhost? ? "#@name.#{region_host}" : region_host
    end

    # Returns path prefix for non +VHOST+ bucket. Path prefix is used
    # instead of +VHOST+ name, e.g. "/bucket_name"
    def path_prefix
      vhost? ? "" : "/#@name"
    end

    # Returns the objects in the bucket and caches the result
    def objects
      Proxy.new(lambda { list_bucket }, :owner => self, :extend => ObjectsExtension)
    end

    # Returns the object with the given key. Does not check whether the
    # object exists. But also does not issue any HTTP requests, so it's
    # much faster than objects.find
    def object(key)
      Object.send(:new, self, :key => key)
    end

    def inspect #:nodoc:
      "#<#{self.class}:#{name}>"
    end

  private

    attr_writer :service

    def create_bucket_configuration(options = {})
      location = options[:location].to_s.downcase if options[:location]
      
      options[:headers] ||= {}
      if location and location != Sndacs::REGION_DEFAULT
        options[:headers][:content_type] = "application/xml"
        options[:body] = "<CreateBucketConfiguration><LocationConstraint>#{location}</LocationConstraint></CreateBucketConfiguration>"
      end

      bucket_request(:put, options)
    end

    def list_bucket(options = {})
      response = bucket_request(:get, :params => options)
      max_keys = options[:max_keys]
      objects_attributes = parse_all_objects_result(response.body)

      # If there are more than 1000 objects S3 truncates listing and
      # we need to request another listing for the remaining objects.
      while parse_is_truncated(response.body)
        next_request_options = {:marker => objects_attributes.last[:key]}

        if max_keys
          break if objects_attributes.length >= max_keys
          next_request_options[:max_keys] = max_keys - objects_attributes.length
        end

        response = bucket_request(:get, :params => options.merge(next_request_options))
        objects_attributes += parse_all_objects_result(response.body)
      end

      objects_attributes.map { |object_attributes| Object.send(:new, self, object_attributes) }
    end

    def bucket_headers(options = {})
      response = bucket_request(:head, :params => options)
    rescue Error::ResponseError => e
      if e.response.code.to_i == 404
        raise Error::ResponseError.exception("NoSuchBucket").new("The specified bucket does not exist.", nil)
      else
        raise e
      end
    end

    def location_constraint
      response = bucket_request(:get, :params => {:location => nil})

      parse_location_constraint(response.body)
    end

    def delete_bucket
      bucket_request(:delete)
    end

    def initialize(service, name, location = nil) #:nodoc:
      self.service = service
      self.name = name

      unless location
        begin
          location = location_constraint
        rescue
          location = Sndacs::REGION_DEFAULT
        end
      end

      self.location = location
    end

    def name=(name)
      raise ArgumentError.new("Invalid bucket name: #{name}") unless name_valid?(name)
      @name = name
    end

    def location=(location)
      @location = location
    end

    def name_valid?(name)
      name =~ /\A[a-z0-9][a-z0-9\._-]{2,254}\Z/i and name !~ /\A#{URI::REGEXP::PATTERN::IPV4ADDR}\Z/
    end

    def bucket_request(method, options = {})
      path = path_prefix
      if options[:path]
          path << '/' unless path[-1,1] == '/'
          path << options[:path]
      end

      service_request(method, options.merge(:host => host, :path => File.expand_path(path)))
    end
  end

end
