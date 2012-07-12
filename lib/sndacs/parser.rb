require 'rexml/document'

module Sndacs

  module Parser
    include REXML

    def rexml_document(xml)
      xml.force_encoding(::Encoding::UTF_8) if xml.respond_to? :force_encoding

      Document.new(xml)
    end

    def parse_all_buckets_result(xml)
      all_buckets = []
      rexml_document(xml).elements.each("ListAllMyBucketsResult/Buckets/Bucket") do |e|
        bucket_attributes = {}
        bucket_attributes[:name] = e.elements["Name"].text

        element_location = e.elements["Location"]
        if element_location
          bucket_attributes[:location] = element_location.text
        else
          bucket_attributes[:location] = REGION_DEFAULT
        end

        all_buckets << bucket_attributes
      end

      all_buckets
    end

    def parse_all_objects_result(xml)
      objects_attributes = []
      rexml_document(xml).elements.each("ListBucketResult/Contents") do |e|
        object_attributes = {}
        object_attributes[:key] = e.elements["Key"].text
        object_attributes[:etag] = e.elements["ETag"].text
        object_attributes[:last_modified] = e.elements["LastModified"].text
        object_attributes[:size] = e.elements["Size"].text

        objects_attributes << object_attributes
      end

      objects_attributes
    end

    def parse_location_constraint(xml)
      location = rexml_document(xml).elements["LocationConstraint"].text
      if location.nil? || location == ''
        location = REGION_DEFAULT
      end

      location
    end

    def parse_copy_object_result(xml)
      object_attributes = {}
      document = rexml_document(xml)
      object_attributes[:etag] = document.elements["CopyObjectResult/ETag"].text
      object_attributes[:last_modified] = document.elements["CopyObjectResult/LastModified"].text
      object_attributes
    end

    def parse_error(xml)
      document = rexml_document(xml)
      code = document.elements["Error/Code"].text
      message = document.elements["Error/Message"].text
      [code, message]
    end

    def parse_is_truncated xml
      rexml_document(xml).elements["ListBucketResult/IsTruncated"].text =='true'
    end
  end

end
