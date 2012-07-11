require 'net/http'

require 'proxies'

require 'sndacs/parser'
require 'sndacs/buckets_extension'
require 'sndacs/connection'

module Sndacs

  class Service
    include Parser
    include Proxies

    attr_reader :access_key_id, :secret_access_key, :use_ssl, :proxy

    # Compares service to other, by <tt>access_key_id</tt> and
    # <tt>secret_access_key</tt>
    def ==(other)
      self.access_key_id == other.access_key_id and self.secret_access_key == other.secret_access_key
    end

    # Creates new service.
    #
    # ==== Options
    # * <tt>:access_key_id</tt> - Access key id (REQUIRED)
    # * <tt>:secret_access_key</tt> - Secret access key (REQUIRED)
    # * <tt>:use_ssl</tt> - Use https or http protocol (false by
    #   default)
    # * <tt>:debug</tt> - Display debug information on the STDOUT
    #   (false by default)
    # * <tt>:timeout</tt> - Timeout to use by the Net::HTTP object
    #   (60 by default)
    def initialize(options = {})
      @access_key_id = options.fetch(:access_key_id, Config.access_key_id)
      @secret_access_key = options.fetch(:secret_access_key, Config.secret_access_key)
      @proxy = options.fetch(:proxy, Config.proxy)
      @timeout = options.fetch(:timeout, Config.timeout)
      @use_ssl = options.fetch(:use_ssl, Config.use_ssl)
      @debug = options.fetch(:debug, Config.debug)

      raise ArgumentError, "Wrong proxy settings. Must specify at least :host option." if @proxy && !@proxy[:host]
    end

    # Returns all buckets in the service and caches the result (see
    # +reload+)
    def buckets
      Proxy.new(lambda { buckets_all }, :owner => self, :extend => BucketsExtension)
    end

    # Returns the bucket with the given name and region. Does not check whether the
    # bucket exists. But also does not issue any HTTP requests, so it's
    # much faster than buckets.find
    def bucket(name, region = nil)
      Bucket.send(:new, self, name, region || REGION_DEFAULT)
    end

    # Returns "http://" or "https://", depends on <tt>:use_ssl</tt>
    # value from initializer
    def protocol
      use_ssl ? "https://" : "http://"
    end

    # Returns 443 or 80, depends on <tt>:use_ssl</tt> value from
    # initializer
    def port
      use_ssl ? 443 : 80
    end

    def inspect #:nodoc:
      "#<#{self.class}:#@access_key_id>"
    end

  private

    def buckets_all
      response = service_request(:get)

      all_buckets = parse_all_buckets_result(response.body)
      all_buckets.map { |bucket| Bucket.send(:new, self, bucket[:name], bucket[:region]) }
    end

    def service_request(method, options = {})
      unless options[:path]
        options[:path] = '/'
      end

      req_path = options[:path]
      if req_path[0,1] != '/'
        req_path = "/#{req_path}"
      end

      connection.request(method, options.merge(:path => req_path))
    end

    def connection
      @connection ||= Connection.new(:access_key_id => @access_key_id,
                                     :secret_access_key => @secret_access_key,
                                     :use_ssl => @use_ssl,
                                     :timeout => @timeout,
                                     :proxy => @proxy,
                                     :debug => @debug)
    end
  end

end
