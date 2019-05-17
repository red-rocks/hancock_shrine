# frozen_string_literal: true
class Shrine
  module Plugins
    # The `compatibility` plugin adds paperclip-like methods, etc
    #     plugin :compatibility
    #

    module Compatibility

      def self.configure(uploader, opts = {})
        # uploader.opts[:Timestampable] = "LOADED"
      end

      def self.load_dependencies(uploader, *)
      end

      module FileMethods
        
        def path
          to_io.path
        end

      end
    end

    register_plugin(:compatibility, Compatibility)
  end
end
