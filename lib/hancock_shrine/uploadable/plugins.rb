module HancockShrine::Uploadable::Plugins
  extend ActiveSupport::Concern
    
  # ALLOWED_TYPES = %w[image/jpeg image/png image/jpg image/pjpeg image/svg image/webp]
  ALLOWED_IMAGE_TYPES = HancockShrine.config.plugin_options[:validation_helpers][:allowed_image_types]
  ALLOWED_TYPES       = HancockShrine.config.plugin_options[:validation_helpers][:allowed_types]
  # MAX_SIZE      = 20*1024*1024 # 20 MB
  # MAX_SIZE      = 15*1024*1024 # 15 MB
  # MAX_SIZE      = 10*1024*1024 # 10 MB
  MAX_SIZE        = HancockShrine.config.plugin_options[:validation_helpers][:max_size]
  MAX_IMAGE_SIZE  = HancockShrine.config.plugin_options[:validation_helpers][:max_image_size]

  included do |base|

    init_plugins(base)

  end

  class_methods do

    def inherited(subclass)
      super(subclass)
      subclass.init_plugins(subclass)
    end

  
    def init_plugins(base)
      HancockShrine.config.plugins.each do |plugin_name|
        plugin_name = plugin_name.to_sym
        plugin_options = HancockShrine.config.plugin_options[plugin_name] || {}

        if_condition = plugin_options.delete(:if)
        if if_condition 
          next if if_condition == :is_image and !@is_image
        end

        unless_condition = plugin_options.delete(:unless)
        if unless_condition 
          next if unless_condition == :is_image and @is_image
        end

        begin
          # puts "#{plugin_name} with_options"
          plugin plugin_name, plugin_options
        rescue Exception => ex
          # puts ex.inspect
    
          # puts "#{plugin_name} solo"
          plugin plugin_name
        end

        if plugin_name == :validation_helpers or plugin_name == :hancock_validations
          if defined?(base) and base and defined?(base::Attacher) and base::Attacher
            base::Attacher.validate do
              if @is_image
                validate_max_size base::MAX_IMAGE_SIZE if base::MAX_IMAGE_SIZE
              else
                validate_max_size base::MAX_SIZE if base::MAX_SIZE
              end
              
              # TODO
              if @is_image
                unless base::ALLOWED_IMAGE_TYPES.blank?
                  if validate_mime_type(base::ALLOWED_IMAGE_TYPES)
                    if file["width"] and store.max_width
                    # if store.max_width
                      validate_max_width store.max_width
                    end
                    if file["height"] and store.max_height
                    # if store.max_height
                      validate_max_height store.max_height
                    end
                  end
                end

              else
                if validate_mime_type(base::ALLOWED_TYPES)
                  # if file["width"] and store.max_width
                  # # if store.max_width
                  #   validate_max_width store.max_width
                  # end
                  # if file["height"] and store.max_height
                  # # if store.max_height
                  #   validate_max_height store.max_height
                  # end
                end
              end
              
            end
          end
        elsif plugin_name == :processing
          class_eval <<-RUBY

            def hancock_processing(action, io, context)
              if action.to_sym == :upload
                context[:location] ||= hancock_location(io, context)
                return io
              end
              original, versions = get_data_from(io, context) do |original, versions|
                begin

                  pipeline = get_pipeline(original)
                  if pipeline
                    versions[:compressed] = pipeline.convert!(nil)
                    pipeline = cropping(pipeline, io, context)

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
          process(:upload) do |io, context|
            hancock_processing(:upload, io, context)
          end
        
        elsif plugin_name == :hancock_derivatives
          class_eval <<-RUBY
            # Attacher.derivatives :hancock_processor do |original|
            Attacher.derivatives_processor do |original, crop: nil|
              # self    #=> #<Shrine::Attacher>
            
              # # record  #=> #<Photo>
              # # name    #=> :image
              # # context #=> { ... }
              # puts 'Attacher.derivatives_processor do |original|'
              # puts 'original'
              # puts original
              # puts 'record'
              # puts record
              # puts 'name'
              # puts name
              # puts 'context'
              # puts context
              opts = { crop: crop }

              self.hancock_derivatives(original, record, name, context, opts)
            end
          RUBY
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
  
  end

end
  