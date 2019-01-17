module HancockShrine::Uploadable
  extend ActiveSupport::Concern
    
  ALLOWED_TYPES = %w[image/jpeg image/png image/jpg image/pjpeg image/svg image/webp]
  MAX_SIZE      = 20*1024*1024 # 20 MB
  # MAX_SIZE      = 15*1024*1024 # 15 MB
  # MAX_SIZE      = 10*1024*1024 # 10 MB

  included do |base|
    
    def self.init_plugins(base)
      plugin :cached_attachment_data # for retaining the cached file across form redisplays
      plugin :restore_cached_data # re-extract metadata when attaching a cached file

      plugin :remote_url, max_size: 20*1024*1024
      # plugin :pretty_location
      # plugin :hancock_location

      # plugin :default_version
      
      plugin :remove_attachment
      plugin :moving
      # plugin :delete_raw
    
      plugin :store_dimensions, analyzer: :ruby_vips

      plugin :validation_helpers
      # File validations (requires `validation_helpers` plugin)
      base::Attacher.validate do
        validate_max_size MAX_SIZE
        if validate_mime_type_inclusion(ALLOWED_TYPES)
          validate_max_width 6000
          validate_max_height 6000
        end
      end
      
      plugin :processing
      # Additional processing (requires `processing` plugin)
      # process(:store) do |io, context|
      #   # ...
      # end

      
      # plugin :timestampable
      # plugin :add_metadata
      # add_metadata :timestamp do |io|
      #   Time.new
      # end

      # add_metadata :exif do |io|
      #   Shrine.with_file(io) do |file|
      #     # begin
      #     #   MiniMagick::Image.new(file.path).exif
      #     # rescue MiniMagick::Error
      #     #   # not a valid image
      #     # end
      #     begin
      #       puts file
      #       image = Vips::Image.new_from_file file
      #       puts image
      #       image.get "exif-data"
      #       puts image.get "exif-data"
      #       image.get "exif-data"
      #     rescue 
      #     end
      #   end
      # end



      # TEMP
      plugin :backgrounding
      # Shrine::Attacher.promote { |data| 
      base::Attacher.promote { |data| 
        # puts "Shrine::Attacher.promote"
        # puts PromoteJob.methods
        # puts data.inspect
        PromoteJob.perform_later(data) 
        # PromoteJob.perform_async(data) 
      }
      # Shrine::Attacher.delete { |data| 
      base::Attacher.delete { |data| 
        # puts "Shrine::Attacher.delete"
        # puts DeleteJob.methods
        # puts data.inspect
        DeleteJob.perform_later(data) 
        # DeleteJob.perform_async(data) 
      }

    
      plugin :cropable
      # def crop_params(target = nil)
      #   puts 'def crop_params(target = nil)'
      #   puts target.inspect
      #   if target
      #     puts target.crop_w
      #     puts target.crop_h
      #     puts target.crop_x
      #     puts target.crop_y
      #   end
      #   return nil if target.nil?
      #   return @crop_params if @crop_params
      #   w = ((target.respond_to?(:crop_w) and target.crop_w) ? target.crop_w.to_i : nil)
      #   h = ((target.respond_to?(:crop_h) and target.crop_h) ? target.crop_h.to_i : nil)
      #   x = ((target.respond_to?(:crop_x) and target.crop_x) ? target.crop_x.to_i : nil)
      #   y = ((target.respond_to?(:crop_y) and target.crop_y) ? target.crop_y.to_i : nil)
        
      #   @crop_params = if w and h and x and y
      #     if imagick?
      #       # IMagick / RMagick / ImageMagick
      #       x = "+#{x}" if x >= 0
      #       y = "+#{y}" if y >= 0
      #       "#{w}x#{h}#{x}#{y}"
      #     elsif vips?
      #       # VIPS
      #       [x, y, w, h].map(&:to_i) 
      #     end
      #   end
      # end
      

      plugin :hancock_versions
    end
    init_plugins(base)

    def vips?
      true
    end
    def imagick?
      !vips?
    end
    
    def self.inherited(subclass)
      Shrine.inherited(subclass)
      subclass.init_plugins(subclass)
    end
  end

end
