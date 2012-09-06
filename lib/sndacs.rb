#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require "base64"
require "cgi"
require "digest/md5"
require "forwardable"
require "net/http"
require "net/https"
require "openssl"
require "rexml/document"
require "time"
require "mime/types"

require "proxies"
require "sndacs/objects_extension"
require "sndacs/buckets_extension"
require "sndacs/parser"
require "sndacs/bucket"
require "sndacs/config"
require "sndacs/connection"
require "sndacs/exceptions"
require "sndacs/object"
require "sndacs/request"
require "sndacs/service"
require "sndacs/signature"
require "sndacs/version"

module Sndacs

  # Bucket default region
  # NOTICE: DO NOT TOUCH THIS!!!
  REGION_DEFAULT = 'huadong-1'

  # Bucket region host template
  # NOTICE: DO NOT TOUCH THIS!!!
  REGION_HOST = 'storage-%s.grandcloud.cn'

  # Object public access host template
  # NOTICE: DO NOT TOUCH THIS!!!
  REGION_CONTENT_HOST = 'storage-%s.sdcloud.cn'

  # Default configurations, see Sndacs::Config for more info
  #Config.access_key_id = ''
  #Config.secret_access_key = ''
  #Config.host = 'storage.grandcloud.cn'
  #Config.content_host = 'storage.sdcloud.cn'
  #Config.proxy = nil
  #Config.timeout = 60
  #Config.use_ssl = false
  #Config.chunk_size = 1048576
  #Config.debug = false

end
