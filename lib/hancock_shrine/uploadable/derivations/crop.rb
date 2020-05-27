module HancockShrine::Uploadable::Deriviations::Crop
  extend ActiveSupport::Concern

  included do
  
    include HancockShrine::Uploadable::Deriviations
    include Shrine::Plugins::Cropable
    derivation :crop do |file, crop_x, crop_y, crop_w, crop_h, opts|
      source.uploader.derivation_crop_handler(file, crop_x, crop_y, crop_w, crop_h)
    end
    

    def derivation_crop_handler(file, crop_x, crop_y, crop_w, crop_h)
      # pipeline = if imagick?
      #   ImageProcessing::MiniMagick.source(file).saver(quality: 90, strip: true)
      # elsif vips?
      #   ImageProcessing::Vips.source(file).saver(quality: 90, strip: true)
      # end
      pipeline = get_pipeline(file)
      if pipeline
        pipeline = pipeline.crop(crop_x.to_i, crop_y.to_i, crop_w.to_i, crop_h.to_i)
        pipeline = pipeline.call!
      end
      pipeline
    end
    
  end
  

end
  