#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

module Sndacs

  class Config

    class << self
      attr_accessor :access_key_id
      attr_accessor :secret_access_key

      attr_accessor :proxy
      attr_accessor :host
      attr_accessor :timeout
      attr_accessor :use_ssl
      attr_accessor :chunk_size
      attr_accessor :debug

      def access_key_id
        @access_key_id ||= ''
      end

      def secret_access_key
        @secret_access_key ||= ''
      end

      def proxy
        @proxy ||= nil
      end

      def host
        @host ||= 'storage.grandcloud.cn'
      end

      def timeout
        @timeout ||= 60
      end

      def use_ssl
        @use_ssl ||= false
      end

      def chunk_size
        @chunk_size ||= 1048576
      end

      def debug
        @debug ||= false
      end
    end

  end

end
