class Shrine
  module Plugins
    # The `hancock_versions` plugin attempts nicer access to :versions plugin for different storages
    #
    #     plugin :hancock_versions
    
    module HancockVersions

      def self.load_dependencies(uploader, *)
        uploader.plugin :versions
        uploader.plugin :default_version, name: :original
      end

      def self.configure(uploader, opts = {})
      end

      
      class VersionsWrapper < Hash

        attr_reader :default_version_name
        def initialize(versions_hash, default_version_name)
          versions_hash ||= {}
          versions_hash.each_pair { |k, v|
            self[k] = v
          }
          @default_version_name = default_version_name
        end

        def method_missing(name, *args, &block)
          version = case name.to_sym
          when :url, :exists?, :path # TODO maybe
            args.pop || default_version_name
          else
            default_version_name
          end
          (self[version] || self[:original]).send(name, *args, &block)
        end

        # HARDFIX
        def respond_to?(meth)
          !!(super || (self[:original] and self[:original].respond_to?(meth)))
        end

      end


      module ClassMethods

        def uploaded_file(object, &block)
          if object.is_a?(Hash) && object.values.none? { |value| value.is_a?(String) }
            versions_hash = object.inject({}) do |result, (name, value)|
              result.merge!(name.to_sym => uploaded_file(value, &block))
            end
            VersionsWrapper.new(versions_hash, default_version_name)
          elsif object.is_a?(Array)
            object.map { |value| uploaded_file(value, &block) }
          else
            super
          end
        end

      end

      module InstanceMethods
      end

      module AttacherMethods

        private
        def convert_after_read(value)
          value = {original: value} if value.is_a?(UploadedFile)
          VersionsWrapper.new(value, default_version_name)
        end

      end

    end

    register_plugin(:hancock_versions, HancockVersions)
  end
end
