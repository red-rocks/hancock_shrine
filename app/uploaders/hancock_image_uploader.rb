# class HancockUploader < Shrine
class HancockImageUploader < HancockShrine::Uploader
  # extend ActiveSupport::Concern
  
  include HancockShrine::BaseUploader

  # def self.inherited(subclass)
  #   # puts 'def inherited(subclass)'
  #   # puts 'HancockUploader < Shrine'
  #   # puts subclass
  #   super(subclass)
  # end


  include ::HancockShrine::Uploadable::UploadEndpoint
  include ::HancockShrine::Uploadable::Deriviations::Crop

end
