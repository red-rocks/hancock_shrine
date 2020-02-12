class Shrine
  module Plugins
    # The `hancock_derivatives` plugin attempts nicer access to :derivatives plugin for different storages
    #
    #     plugin :hancock_derivatives
    
    module HancockDerivatives

      def self.load_dependencies(uploader, *)
        uploader.plugin :derivatives, create_on_promote: true
        # uploader.plugin :default_version, name: :original
      end

      def self.configure(uploader, opts = {})
      end

      
      # class VersionsWrapper < Hash

      #   attr_reader :default_version_name
      #   def initialize(versions_hash, default_version_name)
      #     versions_hash ||= {}
      #     versions_hash.each_pair { |k, v|
      #       self[k] = v
      #     }
      #     @default_version_name = default_version_name
      #   end

      #   def method_missing(name, *args, &block)
      #     version = case name.to_sym
      #     when :url, :exists?, :path # TODO maybe
      #       args.shift || default_version_name
      #     else
      #       default_version_name
      #     end
      #     target = (self[version] || self[:original])
      #     target&.send(name, *args, &block) # TODO (hardfix)
      #   end

      #   # HARDFIX
      #   def respond_to?(meth)
      #     !!(super || (self[:original] and self[:original].respond_to?(meth)))
      #   end

      # end


      # module ClassMethods

      #   def uploaded_file(object, &block)
      #     puts 'def uploaded_file(object, &block)'
      #     if object.is_a?(Hash) && object.values.none? { |value| value.is_a?(String) }
      #       versions_hash = object.inject({}) do |result, (name, value)|
      #         result.merge!(name.to_sym => uploaded_file(value, &block))
      #       end
      #       VersionsWrapper.new(versions_hash, default_version_name)
      #     elsif object.is_a?(Array)
      #       object.map { |value| uploaded_file(value, &block) }
      #     else
      #       super
      #     end
      #   end

      # end

      # module InstanceMethods
      # end

      module AttachmentMethods
        def define_model_methods(name)
          super if defined?(super)

          define_method :"remove_#{name}=" do |value|
            send(:"#{name}_attacher").remove = value
          end

          define_method :"remove_#{name}" do
            # send(:"#{name}_attacher").delete_derivatives
          end

          define_method :"remove_#{name}!" do
            send(:"#{name}_attacher").delete_derivatives
          end

          define_method :"reprocess_#{name}!" do
            _attacher = send(:"#{name}_attacher")
            if _attacher and _attacher.respond_to?(:derivatives)
              # _attacher.remove_derivatives
              return (send(:"#{name}_derivatives!") and self.save!)
            end
            file = send(name)
            file =  file[:original] if file.is_a?(Hash)
            if _attacher.stored?
              self.update!("#{name}": file)
            else
              if _attacher.cached?
                _attacher.store!(name)
                self.save
              end
            end
          end
          define_method :"reprocess_#{name}" do
            _attacher = send(:"#{name}_attacher")
            if _attacher and _attacher.respond_to?(:derivatives)
              # _attacher.remove_derivatives
              return send(:"#{name}_derivatives!")
            end
            file = send(name)
            file =  file[:original] if file.is_a?(Hash)
            if _attacher.stored?
              self.assign_attributes("#{name}": file)
            else
              if _attacher.cached?
                _attacher.store!(name)
              end
            end
          end
          

        end
      end


      module AttacherMethods
        attr_reader :derivatives_processed

        def create_derivatives(*args, storage: nil, **options)
          @derivatives_processed = false
          if ret = super
            @derivatives_processed = true
          end
          return ret
        end

        def remove=(value)
          @remove = value

          change(nil) if remove?
        end

        def remove
          @remove
        end

        private
        def remove?
          remove && remove != "" && remove !~ /\A(0|false)\z/
        end

        
        # include ::HancockShrine::Uploadable::Content    
        def vips?
          HancockShrine.config.vips
        end
        def imagick?
          !vips?
        end

        def get_data_from(io, context)
          if io.is_a?(Hash)
            versions = io
            original = io[:original]
          else
            versions = { original: io }
            original = io
          end
          # original.download
          versions = yield(original, versions) if block_given?
          return original, versions
        end

        def get_pipeline(original)
          # puts 'def get_pipeline(original)'
          original = original[:original] if original.is_a?(Hash)
          source = (original.is_a?(Tempfile) ? original.path : original.download)
          if imagick?
            ImageProcessing::MiniMagick.source(source).saver(saver_opts)
          elsif vips?
            ImageProcessing::Vips.source(source).saver(saver_opts)
          end
        end

        def saver_opts
          HancockShrine.config.plugin_options[:saver][:opts] || {}
        end


        def get_styles(record, name, context, action = :upload)
          styles_method = "#{name}_styles"
    
          if record.method(styles_method).arity == 1
            record.send(styles_method, action)
          else
            record.send(styles_method)
          end
        end
        
        public
        def resize_opts_default
          {sharpen: false, size: :down}
        end

        def process_style(pipeline:, style_name:, style_opts:, io:, context:)
          
          opts = {pipeline: pipeline, style_name: style_name, style_opts: style_opts, io: io, context: context}
          pipeline = pre_process_style(opts)
    
          if style_opts.is_a?(String)
            style_opts = {
              geometry: style_opts
            }
          end
    
          # https://github.com/thoughtbot/paperclip/blob/6661480c5b321709ad44c7ef9572d7f908857a9d/lib/paperclip/geometry_parser_factory.rb
          if geometry = style_opts[:geometry]
            if actual_match = geometry.match(/\b(\d*)x?(\d*)\b(?:,(\d?))?(\@\>|\>\@|[\>\<\#\@\%^!])?/i)
              width = actual_match[1].to_i
              height = actual_match[2].to_i
              orientation = actual_match[3]
              modifier = actual_match[4]
    
              # https://github.com/thoughtbot/paperclip/blob/6661480c5b321709ad44c7ef9572d7f908857a9d/lib/paperclip/geometry.rb
              ### TODO; may be not 'resize_to_limit'
              pipeline = case modifier
              when '!', '#'
                pipeline.resize_to_fill(width, height, resize_opts_default)
              when '>'
                pipeline.resize_to_limit(width, height, resize_opts_default)
              when '<'
                pipeline.resize_to_limit(width, height, resize_opts_default)
              else
                pipeline.resize_to_limit(width, height, resize_opts_default)
              end
            end
          end
    
          if format = style_opts[:format]
            pipeline = pipeline.convert(format)
          end
          
          opts = {pipeline: pipeline, style_name: style_name, style_opts: style_opts, io: io, context: context}
          pipeline = post_process_style(opts)
    
          pipeline.call!
        end
        def pre_process_style(pipeline:, style_name:, style_opts:, io:, context:)
          pipeline
        end
        def post_process_style(pipeline:, style_name:, style_opts:, io:, context:)
          pipeline
        end



        def hancock_derivatives(original, record, name, context, opts = {})
          derivatives = {}
          if record.try("#{name}_is_image?")
            pipeline = get_pipeline(original)
            derivatives[:compressed] = pipeline.convert!(nil)
            
            # ### TODO - more flexible
            # pipeline, original, context = cropping(pipeline, original, context) if respond_to?(:cropping)
            if crop = (opts[:crop] || (context[:metadata] and context[:metadata][:crop]))
              crop = crop.with_indifferent_access
              crop_array = [
                crop[:crop_x].to_i, 
                crop[:crop_y].to_i, 
                crop[:crop_w].to_i, 
                crop[:crop_h].to_i
              ]
              pipeline = pipeline.crop(*crop_array)
              context[:metadata][:crop] = crop if context[:metadata]
            end
          end
            
          styles = get_styles(record, name, context)
          styles.each_pair do |style_name, style_opts|
            opts = {
              pipeline: pipeline,
              style_name: style_name,
              style_opts: style_opts, 
              io: original, 
              context: context
            }
            derivatives[style_name] = process_style(opts)
          end
          # puts derivatives.inspect
          derivatives.compact

        end

      end

    end

    register_plugin(:hancock_derivatives, HancockDerivatives)
  end
end
