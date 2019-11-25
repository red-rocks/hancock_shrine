module HancockShrine::Uploadable::Content
  extend ActiveSupport::Concern

  included do

    
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

end
    