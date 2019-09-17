module HancockShrine::Uploadable::Content
  extend ActiveSupport::Concern

  included do

    def hancock_model
      self.class.model
    end
    def hancock_field_name
      self.class.field_name
    end


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

  end

  class_methods do

    def hancock_model
      # puts 'def model'
      # puts name.inspect
      # puts name.sub(/Uploader$/, "").inspect
      # puts name.sub(/Uploader$/, "").underscore.inspect
      # puts name.sub(/Uploader$/, "").underscore.split("_").inspect
      # puts name.sub(/Uploader$/, "").underscore.split("_")[0...-1].inspect
      # puts "____________________________"
      @model ||= name.sub(/Uploader$/, "").underscore.split("_")[0...-1].map(&:capitalize).join.camelize.constantize
    end
    def hancock_field_name
      @field_name ||= name.sub(/Uploader$/, "").underscore.split("_")[-1]
    end

  end

end
    