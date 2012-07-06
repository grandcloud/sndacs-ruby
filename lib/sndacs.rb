require "base64"
require "cgi"
require "digest/md5"
require "forwardable"
require "net/http"
require "net/https"
require "openssl"
require "rexml/document"
require "time"

require "proxies"
require "sndacs/objects_extension"
require "sndacs/buckets_extension"
require "sndacs/parser"
require "sndacs/bucket"
require "sndacs/connection"
require "sndacs/exceptions"
require "sndacs/object"
require "sndacs/request"
require "sndacs/service"
require "sndacs/signature"
require "sndacs/version"

module Sndacs
  # Default (and only) host serving grand cloud stuff
  HOST = "storage.grandcloud.cn"
end
