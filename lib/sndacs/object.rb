module Sndacs

  # Class responsible for handling objects stored in CS buckets
  class Object
    include Parser
    extend Forwardable

    attr_accessor :content_type, :content_disposition, :content_encoding, :cache_control
    attr_reader :last_modified, :etag, :size, :bucket, :key, :acl, :storage_class, :metadata
    attr_writer :content

    def_instance_delegators :bucket, :name, :service, :bucket_request, :vhost?, :host, :path_prefix
    def_instance_delegators :service, :protocol, :port, :access_key_id, :secret_access_key
    private_class_method :new

    # Compares the object with other object. Returns true if the key
    # of the objects are the same, and both have the same buckets (see
    # Bucket equality)
    def ==(other)
      other.equal?(self) || (other.instance_of?(self.class) && self.key == other.key && self.bucket == other.bucket)
    end

    # Returns full key of the object: e.g. <tt>bucket-name/object/key.ext</tt>
    def full_key
      [name, key].join("/")
    end

    # Assigns a new +key+ to the object, raises ArgumentError if given
    # key is not valid key name
    def key=(key)
      raise ArgumentError.new("Invalid key name: #{key}") unless key_valid?(key)
      @key ||= key
    end

    # Assigns a new ACL to the object. Please note that ACL is not
    # retrieved from the server and set to "public-read" by default.
    #
    # ==== Example
    #   object.acl = :public_read
    def acl=(acl)
      @acl = acl.to_s.gsub("_", "-") if acl
    end

    # Assigns a new storage class (RRS) to the object. Please note
    # that the storage class is not retrieved from the server and set
    # to "STANDARD" by default.
    #
    # ==== Example
    #   object.storage_class = :reduced_redundancy
    def storage_class=(storage_class)
      @storage_class = storage_class.to_s.upcase if storage_class
    end

    # Retrieves the object from the server. Method is used to download
    # object information only (content type, size and so on). It does
    # NOT download the content of the object (use the #content method
    # to do it).
    def retrieve
      object_headers

      self
    end

    # Downloads the content of the object, and caches it. Pass true to
    # clear the cache and download the object again.
    def content(reload = false)
      return @content if defined?(@content) and not reload

      get_object

      @content
    end

    # Saves the object, returns true if successfull.
    # ==== Options
    # request headers

    def save(options = {})
      put_object(options)
      true
    end

    # copies the file from another key and/or bucket.
    #
    # ==== Options
    # * <tt>:key</tt> - key for copy
    # * <tt>:bucket</tt> - bucket's name which the source file stored
    # * <tt>:x_snda_metadata..</tt> - params for copy which is not nessary
    #  
    def copy(options = {})
      copy_object(options)
      retrieve
      true
    end

    # Destroys the file on the server
    def destroy
      delete_object

      true
    end

    # Returns Object's URL using protocol specified in service,
    # Return url public reachable when the object is public accessible and public_accessible is true 
    # public_accessible given.Default to false
    # e.g. <tt>http://storage.grandcloud.cn/bucket/key/file.extension</tt>
    def url(public_accessible = false)
      URI.escape("#{protocol}#{host(public_accessible)}/#{path_prefix}#{key}")
    end

    # Returns Object's CNAME URL (without <tt>storage.grandcloud.cn</tt>
    # suffix) using protocol specified in Service,
    # e.g. <tt>http://domain.com/key/with/path.extension</tt>. (you
    # have to set the CNAME in your DNS before using the CNAME URL
    # schema).
    def cname_url
      URI.escape("#{protocol}#{name}/#{key}") if bucket.vhost?
    end

    # Returns a temporary url to the object that expires on the
    # timestamp given. Defaults to 5min expire time.
    def temporary_url(expires_at = Time.now + 3600)
      url = URI.escape("#{protocol}#{host(true)}/#{path_prefix}#{key}")
      signature = Signature.generate_temporary_url_signature(:bucket => name,
                                                             :resource => key,
                                                             :expires_at => expires_at,
                                                             :secret_access_key => secret_access_key)

      "#{url}?SNDAAccessKeyId=#{access_key_id}&Expires=#{expires_at.to_i.to_s}&Signature=#{signature}"
    end

    # Retrieves the object from the server, returns true if the object
    # exists or false otherwise. Uses #retrieve method, but catches
    # Sndacs::Error::NoSuchKey exception and returns false when it happens
    def exists?
      retrieve

      true
    rescue Error::NoSuchKey
      false
    end

    def inspect #:nodoc:
      "#<#{self.class}:/#{name}/#{key}>"
    end

  private

    attr_writer :last_modified, :etag, :size, :original_key, :bucket

    def copy_object(options = {})
      key = options[:key] or raise ArgumentError, "No key given"
      raise ArgumentError.new("Invalid key name: #{key}") unless key_valid?(key)
      bucket = options[:bucket] || self.bucket

      headers = {}

      #headers[:x_snda_acl] = options[:acl] || acl || "public-read"
      headers[:content_type] = options[:content_type] || content_type || content_type_for_key
      headers[:content_encoding] = options[:content_encoding] if options[:content_encoding]
      headers[:content_disposition] = options[:content_disposition] if options[:content_disposition]
      headers[:cache_control] = options[:cache_control] if options[:cache_control]
      headers[:x_snda_copy_source] = [bucket,key].join("/")
      headers[:x_snda_metadata_directive] = options[:replace] == false ? "COPY" : "REPLACE"
      headers[:x_snda_copy_source_if_match] = options[:if_match] if options[:if_match]
      headers[:x_snda_copy_source_if_none_match] = options[:if_none_match] if options[:if_none_match]
      headers[:x_snda_copy_source_if_unmodified_since] = options[:if_modified_since] if options[:if_modified_since]
      headers[:x_snda_copy_source_if_modified_since] = options[:if_unmodified_since] if options[:if_unmodified_since]
      headers = merge_usermetadata_toheader(options,headers)    
      response = object_request(:put,:headers => headers)
      #response.body
      #true
    end

    def get_object(options = {})
      response = object_request(:get, options)

      parse_headers(response)
    end

    def object_headers(options = {})
      response = object_request(:head, options)

      parse_headers(response)
    rescue Error::ResponseError => e
      if e.response.code.to_i == 404
        raise Error::ResponseError.exception("NoSuchKey").new("The specified key does not exist.", nil)
      else
        raise e
      end
    end

    def put_object(options={})
      response = object_request(:put, :body => content, :headers => dump_headers(options))

      parse_headers(response)
      retrieve
    end

    def delete_object(options = {})
      object_request(:delete)
    end

    def initialize(bucket, options = {})
      self.bucket = bucket
      self.key = options[:key]
      self.last_modified = options[:last_modified]
      self.etag = options[:etag]
      self.size = options[:size]
      self.cache_control = options[:cache_control]
    end

    def object_request(method, options = {})
      bucket_request(method, options.merge(:path => key))
    end

    def last_modified=(last_modified)
      @last_modified = Time.parse(last_modified) if last_modified
    end

    def etag=(etag)
      @etag = etag[1..-2] if etag
    end

    def key_valid?(key)
      if (key.nil? or key.empty? or key =~ %r#//#)
        false
      else
        true
      end
    end

    def content_type_for_key
         if mime_type = MIME::Types.type_for(key).first
            mime_type.content_type
         else
            "application/octet-stream"
         end
    end

    def dump_headers(options={})
      headers = {}
      #headers[:x_snda_acl] = @acl || "public-read"
      #headers[:x_snda_storage_class] = @storage_class || "STANDARD"
      headers[:content_type] = options[:content_type] || @content_type || content_type_for_key
      headers[:content_encoding] = options[:content_encoding] || @content_encoding if @content_encoding
      headers[:content_disposition] = options[:content_disposition] || @content_disposition if @content_disposition
      headers[:cache_control] = options[:cache_control] || @cache_control if @cache_control
      headers = merge_usermetadata_toheader(options,headers)
      headers
    end
    
    def merge_usermetadata_toheader(options,headers)
        user_meta_data_prefix = "x-snda-meta-"
        options.each do |key,value|
          parse_key = key.to_s.gsub("_","-").downcase
          if parse_key[0,user_meta_data_prefix.length] === user_meta_data_prefix
              headers[parse_key] = value 
          end
        end
        headers
    end
 
    def parse_headers(response)
      @metadata = response.to_hash.select { |k, v| k.to_s.start_with?("x-snda-meta") }
      self.etag = response["etag"] if response.key?("etag")
      self.content_type = response["content-type"] if response.key?("content-type")
      self.content_disposition = response["content-disposition"] if response.key?("content-disposition")
      self.cache_control = response["cache-control"] if response.key?("cache-control")
      self.content_encoding = response["content-encoding"] if response.key?("content-encoding")
      self.last_modified = response["last-modified"] if response.key?("last-modified")
      if response.key?("content-range")
        self.size = response["content-range"].sub(/[^\/]+\//, "").to_i
      else
        self.size = response["content-length"]
        self.content = response.body unless response.body.nil?
      end
    end
  end

end
