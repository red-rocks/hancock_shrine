module HancockShrine::Uploadable
  extend ActiveSupport::Concern
    
  # ALLOWED_TYPES = %w[image/jpeg image/png image/jpg image/pjpeg image/svg image/webp]
  ALLOWED_TYPES = HancockShrine.config.plugin_options[:validation_helpers][:allowed_types]
  # MAX_SIZE      = 20*1024*1024 # 20 MB
  # MAX_SIZE      = 15*1024*1024 # 15 MB
  # MAX_SIZE      = 10*1024*1024 # 10 MB
  MAX_SIZE      = HancockShrine.config.plugin_options[:validation_helpers][:max_size]

  included do |base|

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
      source = (original.is_a?(Tempfile) ? original.path : original.download)
      if imagick?
        ImageProcessing::MiniMagick.source(source).saver(saver_opts)
      elsif vips?
        ImageProcessing::Vips.source(source).saver(saver_opts)
      end
    end


    def max_width
      HancockShrine.config.plugin_options[:validation_helpers][:max_width]
    end
    def max_height
      HancockShrine.config.plugin_options[:validation_helpers][:max_height]
    end


    def saver_opts
      HancockShrine.config.plugin_options[:saver][:opts] || {}
    end

    def get_styles(context, action)
      name = context[:name].to_s
      styles_method = name + "_styles"

      if context[:record].method(styles_method).arity == 1
        context[:record].send(styles_method, action)
      else
        context[:record].send(styles_method)
      end
    end

    def resize_opts_default
      {sharpen: false, size: :down}
    end


    def process_style(pipeline:, style_name:, style_opts:, io:, context:)

      pipeline = pre_process_style(pipeline, style_name, style_opts, io, context)

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

      pipeline = post_process_style(pipeline, style_name, style_opts, io, context)

      pipeline.call!
    end
    def pre_process_style(pipeline:, style_name:, style_opts:, io:, context:)
      pipeline
    end
    def post_process_style(pipeline:, style_name:, style_opts:, io:, context:)
      pipeline
    end


    init_plugins(base)
  end

  class_methods do
    
    def init_plugins(base)
      # puts 
      # puts "init_plugins #{base}"

      HancockShrine.config.plugins.each do |plugin_name|
        plugin_name = plugin_name.to_sym
        begin
          # puts "#{plugin_name} with_options"
          plugin plugin_name, HancockShrine.config.plugin_options[plugin_name] || {}
        rescue
          # puts "#{plugin_name} solo"
          plugin plugin_name
        end

        if plugin_name == :validation_helpers
          if defined?(base) and base and defined?(base::Attacher) and base::Attacher
            base::Attacher.validate do
              validate_max_size MAX_SIZE
              if validate_mime_type_inclusion(ALLOWED_TYPES)
                validate_max_width store.max_width
                validate_max_height store.max_height
              end
            end
          end
        elsif plugin_name == :processing
          class_eval <<-RUBY

            def hancock_processing(action, io, context)
              puts 'def hancock_processing(action, io, context)'
              original, versions = get_data_from(io, context) do |original, versions|
                begin

                  pipeline = get_pipeline(original)
                  return versions if pipeline.blank?

                  versions[:compressed] = pipeline.convert!(nil)
                  if _crop_params = crop_params(context[:record])
                    pipeline = pipeline.crop(*_crop_params)
                    
                    io.metadata[:crop] ||= {
                      x: crop_params[0],
                      y: crop_params[1],
                      w: crop_params[2],
                      h: crop_params[3],
                    } if io.metadata
                  end

                  case action.to_sym
                  when :store, :recache
                    styles = get_styles(context, action.to_sym)

                    styles.each_pair do |style_name, style_opts|
                      opts = {
                        pipeline: pipeline,
                        style_name: style_name,
                        style_opts: style_opts, 
                        io: io, 
                        context: context
                      }
                      versions[style_name] = process_style(opts)
                    end
                  else
                  end
                rescue
                end
                versions
              end
              versions.compact
            end
          RUBY
          process(:store) do |io, context|
            hancock_processing(:store, io, context)
          end
          process(:recache) do |io, context|
            hancock_processing(:recache, io, context)
          end
        end

      end


      # plugin :cached_attachment_data
      # plugin :restore_cached_data # re-extract metadata when attaching a cached file

      # plugin :remote_url, max_size: 20*1024*1024
      # # plugin :pretty_location
      # # plugin :hancock_location

      # # plugin :default_version
      
      # plugin :remove_attachment
      # plugin :moving
      # # plugin :delete_raw
    
      # plugin :store_dimensions, analyzer: :ruby_vips

      # plugin :validation_helpers
      # # File validations (requires `validation_helpers` plugin)
      # if defined?(base) and base and defined?(base::Attacher) and base::Attacher
      #   base::Attacher.validate do
      #     validate_max_size MAX_SIZE
      #     if validate_mime_type_inclusion(ALLOWED_TYPES)
      #       validate_max_width 6000
      #       validate_max_height 6000
      #     end
      #   end
      # end
      
      # plugin :processing
      # # Additional processing (requires `processing` plugin)
      # # process(:store) do |io, context|
      # #   # ...
      # # end

      
      # # plugin :timestampable
      # # plugin :add_metadata
      # # add_metadata :timestamp do |io|
      # #   Time.new
      # # end

      # # add_metadata :exif do |io|
      # #   Shrine.with_file(io) do |file|
      # #     # begin
      # #     #   MiniMagick::Image.new(file.path).exif
      # #     # rescue MiniMagick::Error
      # #     #   # not a valid image
      # #     # end
      # #     begin
      # #       puts file
      # #       image = Vips::Image.new_from_file file
      # #       puts image
      # #       image.get "exif-data"
      # #       puts image.get "exif-data"
      # #       image.get "exif-data"
      # #     rescue 
      # #     end
      # #   end
      # # end



      # # TEMP
      # plugin :backgrounding
      # # Shrine::Attacher.promote { |data| 
      # base::Attacher.promote { |data| 
      #   # puts "Shrine::Attacher.promote"
      #   # puts PromoteJob.methods
      #   # puts data.inspect
      #   PromoteJob.perform_later(data) 
      #   # PromoteJob.perform_async(data) 
      # }
      # # Shrine::Attacher.delete { |data| 
      # base::Attacher.delete { |data| 
      #   # puts "Shrine::Attacher.delete"
      #   # puts DeleteJob.methods
      #   # puts data.inspect
      #   DeleteJob.perform_later(data) 
      #   # DeleteJob.perform_async(data) 
      # }

    
      # plugin :cropable
      # # def crop_params(target = nil)
      # #   puts 'def crop_params(target = nil)'
      # #   puts target.inspect
      # #   if target
      # #     puts target.crop_w
      # #     puts target.crop_h
      # #     puts target.crop_x
      # #     puts target.crop_y
      # #   end
      # #   return nil if target.nil?
      # #   return @crop_params if @crop_params
      # #   w = ((target.respond_to?(:crop_w) and target.crop_w) ? target.crop_w.to_i : nil)
      # #   h = ((target.respond_to?(:crop_h) and target.crop_h) ? target.crop_h.to_i : nil)
      # #   x = ((target.respond_to?(:crop_x) and target.crop_x) ? target.crop_x.to_i : nil)
      # #   y = ((target.respond_to?(:crop_y) and target.crop_y) ? target.crop_y.to_i : nil)
        
      # #   @crop_params = if w and h and x and y
      # #     if imagick?
      # #       # IMagick / RMagick / ImageMagick
      # #       x = "+#{x}" if x >= 0
      # #       y = "+#{y}" if y >= 0
      # #       "#{w}x#{h}#{x}#{y}"
      # #     elsif vips?
      # #       # VIPS
      # #       [x, y, w, h].map(&:to_i) 
      # #     end
      # #   end
      # # end
      

      # plugin :hancock_versions
    end
    
    def inherited(subclass)
      ::Shrine.inherited(subclass)
      subclass.init_plugins(subclass)
    end

  end

end
