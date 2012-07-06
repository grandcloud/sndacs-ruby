module Sndacs

  # Class responsible for generating signatures to requests.
  #
  # Implements algorithm defined by GrandCloud Web Services to sign
  # request with secret private credentials
  #
  # === See
  # https://cs-console.grandcloud.cn/public/docs/GrandCloud_Storage_Developer_Guide.pdf

  class Signature

    # Generates signature for given parameters
    #
    # ==== Options
    # * <tt>:host</tt> - Hostname
    # * <tt>:request</tt> - Net::HTTPRequest object with correct
    #   headers
    # * <tt>:access_key_id</tt> - Access key id
    # * <tt>:secret_access_key</tt> - Secret access key
    #
    # ==== Returns
    # Generated signature string for given hostname and request
    def self.generate(options)
      request = options[:request]
      access_key_id = options[:access_key_id]

      options.merge!(:headers => request, :method => request.method, :resource => request.path)

      signature = canonicalized_signature(options)

      "SNDA #{access_key_id}:#{signature}"
    end

    # Generates temporary URL signature for given resource
    #
    # ==== Options
    # * <tt>:bucket</tt> - Bucket in which the resource resides
    # * <tt>:resource</tt> - Path to the resouce you want to create
    #   a temporary link to
    # * <tt>:secret_access_key</tt> - Secret access key
    # * <tt>:expires_at</tt> - Unix time stamp of when the resouce
    #   link will expire
    # * <tt>:method</tt> - HTTP request method you want to use on
    #   the resource, defaults to GET
    # * <tt>:headers</tt> - Any additional HTTP headers you intend
    #   to use when requesting the resource
    def self.generate_temporary_url_signature(options)
      bucket = options[:bucket]
      resource = options[:resource]
      secret_access_key = options[:secret_access_key]
      expires = options[:expires_at]

      headers = options[:headers] || {}
      headers.merge!("date" => expires.to_i.to_s)

      options.merge!(:resource => "/#{bucket}/#{URI.escape(resource)}",
                     :method => options[:method] || :get,
                     :headers => headers)
      signature = canonicalized_signature(options)

      CGI.escape(signature)
    end

    # Generates temporary URL for given resource
    #
    # ==== Options
    # * <tt>:bucket</tt> - Bucket in which the resource resides
    # * <tt>:resource</tt> - Path to the resouce you want to create
    #   a temporary link to
    # * <tt>:access_key</tt> - Access key
    # * <tt>:secret_access_key</tt> - Secret access key
    # * <tt>:expires_at</tt> - Unix time stamp of when the resouce
    #   link will expire
    # * <tt>:method</tt> - HTTP request method you want to use on
    #   the resource, defaults to GET
    # * <tt>:headers</tt> - Any additional HTTP headers you intend
    #   to use when requesting the resource
    def self.generate_temporary_url(options)
      bucket = options[:bucket]
      resource = options[:resource]
      access_key = options[:access_key]
      expires = options[:expires_at].to_i
      signature = generate_temporary_url_signature(options)

      url = "http://#{Sndacs::HOST}/#{bucket}/#{resource}"
      url << "?SNDAAccessKeyId=#{access_key}"
      url << "&Expires=#{expires}"
      url << "&Signature=#{signature}"
    end

    private

    def self.canonicalized_signature(options)
      headers = options[:headers] || {}
      host = options[:host] || ""
      resource = options[:resource]
      access_key_id = options[:access_key_id]
      secret_access_key = options[:secret_access_key]

      http_verb = options[:method].to_s.upcase
      content_md5 = headers["content-md5"] || ""
      content_type = headers["content-type"] || ""
      date = headers["x-snda-date"].nil? ? headers["date"] : ""
      canonicalized_resource = canonicalized_resource(host, resource)
      canonicalized_snda_headers = canonicalized_snda_headers(headers)

      string_to_sign = ""
      string_to_sign << http_verb
      string_to_sign << "\n"
      string_to_sign << content_md5
      string_to_sign << "\n"
      string_to_sign << content_type
      string_to_sign << "\n"
      string_to_sign << date
      string_to_sign << "\n"
      string_to_sign << canonicalized_snda_headers
      string_to_sign << canonicalized_resource

      digest = OpenSSL::Digest::Digest.new("sha1")
      hmac = OpenSSL::HMAC.digest(digest, secret_access_key, string_to_sign)
      base64 = Base64.encode64(hmac)
      base64.chomp
    end

    # Helper method for extracting header fields from Net::HTTPRequest
    # and preparing them for singing in #generate method
    #
    # ==== Parameters
    # * <tt>request</tt> - Net::HTTPRequest object with header fields
    #   filled in
    #
    # ==== Returns
    # String containing interesting header fields in suitable order
    # and form
    def self.canonicalized_snda_headers(request)
      headers = []

      # 1. Convert each HTTP header name to lower-case. For example,
      # "X-Amz-Date" becomes "x-snda-date".
      request.each { |key, value| headers << [key.downcase, value] if key =~ /\Ax-snda-/io }
      #=> [["c", 0], ["a", 1], ["a", 2], ["b", 3]]

      # 2. Sort the collection of headers lexicographically by header
      # name.
      headers.sort!
      #=> [["a", 1], ["a", 2], ["b", 3], ["c", 0]]

      # 3. Combine header fields with the same name into one
      # "header-name:comma-separated-value-list" pair as prescribed by
      # RFC 2616, section 4.2, without any white-space between
      # values. For example, the two metadata headers
      # "x-snda-meta-username: fred" and "x-snda-meta-username: barney"
      # would be combined into the single header "x-snda-meta-username:
      # fred,barney".
      combined_headers = headers.inject([]) do |new_headers, header|
        existing_header = new_headers.find { |h| h.first == header.first }
        if existing_header
          existing_header.last << ",#{header.last}"
        else
          new_headers << header
        end
      end
      #=> [["a", "1,2"], ["b", "3"], ["c", "0"]]

      # 4. "Un-fold" long headers that span multiple lines (as allowed
      # by RFC 2616, section 4.2) by replacing the folding white-space
      # (including new-line) by a single space.
      unfolded_headers = combined_headers.map do |header|
        key = header.first
        value = header.last
        value.gsub!(/\s+/, " ")
        [key, value]
      end

      # 5. Trim any white-space around the colon in the header. For
      # example, the header "x-snda-meta-username: fred,barney" would
      # become "x-snda-meta-username:fred,barney"
      joined_headers = unfolded_headers.map do |header|
        key = header.first.strip
        value = header.last.strip
        "#{key}:#{value}"
      end

      # 6. Finally, append a new-line (U+000A) to each canonicalized
      # header in the resulting list. Construct the
      # CanonicalizedResource element by concatenating all headers in
      # this list into a single string.
      joined_headers << "" unless joined_headers.empty?
      joined_headers.join("\n")
    end

    # Helper methods for extracting caninocalized resource address
    #
    # ==== Parameters
    # * <tt>host</tt> - Hostname
    # * <tt>request</tt> - Net::HTTPRequest object with header fields
    #   filled in
    #
    # ==== Returns
    # String containing extracted canonicalized resource
    def self.canonicalized_resource(host, resource)
      # 1. Start with the empty string ("").
      string = ""

      # 2. If the request specifies a bucket using the HTTP Host
      # header (virtual hosted-style), append the bucket name preceded
      # by a "/" (e.g., "/bucketname"). For path-style requests and
      # requests that don't address a bucket, do nothing. For more
      # information on virtual hosted-style requests, see Virtual
      # Hosting of Buckets.
      bucket_name = host.sub(/\.?storage\.grandcloud\.cn\Z/, "")
      string << "/#{bucket_name}" unless bucket_name.empty?

      # 3. Append the path part of the un-decoded HTTP Request-URI,
      # up-to but not including the query string.
      uri = URI.parse(resource)
      string << uri.path

      # 4. If the request addresses a sub-resource, like ?location,
      # ?acl, or ?torrent, append the sub-resource including question
      # mark.
      sub_resources = [
        "acl",
        "location",
        "logging",
        "notification",
        "partNumber",
        "policy",
        "requestPayment",
        "torrent",
        "uploadId",
        "uploads",
        "versionId",
        "versioning",
        "versions",
        "website"
      ]
      string << "?#{$1}" if uri.query =~ /&?(#{sub_resources.join("|")})(?:&|=|\Z)/
      string
    end
  end

end
