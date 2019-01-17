# frozen_string_literal: true

class Shrine
  module Plugins
    # The `default_versions` plugin set default version for file
    #
    #     plugin :default_version
    #
    # Default version name is `original` but you can change it:
    #
    #     plugin :default_version, name: :main
    #
    # Required `versions` plugin
    module DefaultVersion
      def self.load_dependencies(uploader, *)
        uploader.plugin :versions
      end

      def self.configure(uploader, opts = {})
        uploader.opts[:default_version_name] = opts.fetch(:name, uploader.opts[:default_version_name] || :original)
      end

      module ClassMethods

        def default_version_name
          opts[:default_version_name]
        end
      end



      module AttacherMethods
        
        def url(version = default_version_name, **options)
          # super(version, **options)
          super
        end

        private 
        def default_version_name
          store.class.default_version_name
        end

      end
    end

    register_plugin(:default_version, DefaultVersion)
  end
end
