class Shrine
  module Plugins
    # The `hancock_location` plugin attempts to generate a nicer folder structure
    # for uploaded files (paperclip-like).
    #
    #     plugin :hancock_location
    #
    # Based on PrettyLocation
    module HancockLocation
      def self.configure(uploader, opts = {})
        # uploader.opts[:hancock_location_namespace] = opts.fetch(:namespace, uploader.opts[:hancock_location_namespace])
        # uploader.opts[:hancock_location_namespace] = opts.fetch(:namespace, "_") # PAPERCLIP fallback
        uploader.opts[:hancock_location_namespace] = opts.fetch(:namespace, "/") # PAPERCLIP fallback actual
        uploader.opts[:hancock_location_replace_name] = opts.fetch(:replace_name, false) # PAPERCLIP fallback actual
      end

      module InstanceMethods
        def generate_location(io, context)
          hancock_location(io, context)
        end

        def hancock_location(io, context)
          # puts 'def hancock_location(io, context)'
          # puts context.keys.inspect
          # puts context.inspect
          
          if context[:record]
            type = class_location(context[:record].class) if context[:record].class.name
            if context[:record].respond_to?(:id)
              id = context[:record].id
              id_partition = id.to_s.scan(/.{4}/).join("/")
              id_partition_in_8 = id.to_s.scan(/.{8}/).join("/")
            end
          else
            type = class_location(context[:model]) if context[:model]
              
          end
          # name = context[:name]
          field_name = context[:field_name].to_s.pluralize
          version = context[:version] || context [:derivative] # versions and derivatives compatibility
          dirname, slash, basename = basic_location(io, metadata: context[:metadata] || {}).rpartition("/")
          # basename = "#{context[:version]}-#{basename}" if context[:version]
          
          extension   = ".#{io.extension}" if io.is_a?(UploadedFile) && io.extension
          extension ||= File.extname(extract_filename(io).to_s).downcase
          original = (context[:record] and context[:field_name] and context[:record].send(context[:field_name]))
          # if original and original.respond_to?(:[])
          if original and original.is_a?(Hash)
            original = original[:original]
          end
          if !!opts[:hancock_location_replace_name]
            basename = if opts[:hancock_location_replace_name].is_a?(Proc)
              opts[:hancock_location_replace_name].call(self, io, context) rescue nil
            else 
              nil
            end
          else
            basename = if original and (basename = original.original_filename)
              # File.basename(basename, extension).to_url
              File.basename(basename, ".*").to_url
            end rescue nil
          end
          basename = SecureRandom.hex if basename.blank?
          # original = dirname + slash + basename + extension

          # [type, id, name, original].compact.join("/")
          # [type, id_partition, name, dirname].compact.join("/")
          # [type, id_partition_in_8, name, original].compact.join("/")
          # [type, id_partition, name, version, basename + extension].compact.join("/")
          # [type, name, id_partition, version, basename + extension].compact.join("/") # PAPERCLIP fallback
          [
            type, 
            field_name, 
            id_partition, 
            version, 
            (basename + extension)
          ].reject(&:blank?).join("/") # PAPERCLIP fallback
        end

        private

        def class_location(klass)
          # parts = klass.name.downcase.split("::")
          parts = klass.name.underscore.split("/") # Paperclip fallback
          if separator = opts[:hancock_location_namespace]
            parts.join(separator)
          else
            parts.last
          end.pluralize # PAPERCLIP fallback
        end
      end
    end

    register_plugin(:hancock_location, HancockLocation)
  end
end
