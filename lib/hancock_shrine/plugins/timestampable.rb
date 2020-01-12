# frozen_string_literal: true
class Shrine
  module Plugins
    # The `timestampable` plugin adds paperclip-like timestamps in url 
    #     plugin :timestampable
    #
    # Uses :add_metadata plugin for updating timestamp after each file update

    module Timestampable

      def self.configure(uploader, opts = {})
        uploader.opts[:Timestampable] = "LOADED"
      end

      def self.load_dependencies(uploader, *)
        uploader.plugin :add_metadata
        uploader.add_metadata :timestamp do |io|
          Time.new.to_i
        end
      end

      # module AttacherMethods
        
      #   def url(**options)    
      #     timestamp = metadata["timestamp"]
      #     # timestamp ||= 
      #     _url = super
      #     if _url.index("?")
      #       "#{_url}&#{timestamp.to_i}"
      #     else
      #       "#{_url}?#{timestamp.to_i}"
      #     end
      #   end
        
      # end
      module FileMethods
        
        def url(*options, **hash_options)
          _options = options.extract_options!.merge(hash_options)
          _options.reverse_merge!(timestamp: true)
          timestamp = _options.delete(:timestamp) ? metadata["timestamp"] : nil
          _url = super(**_options)
          if timestamp
            _url = if _url.index("?")
              "#{_url}&#{timestamp.to_i}"
            else
              "#{_url}?#{timestamp.to_i}"
            end
          end
          _url
        end

      end

      # module FileMethods
      #   delegate :url, to: :attacher
      # end
      
    end

    register_plugin(:timestampable, Timestampable)
  end
end
