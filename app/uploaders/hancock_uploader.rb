# class HancockUploader < Shrine
class HancockUploader < HancockShrine::Uploader
  def self.is_image
    false
  end
  def self.init_plugins?
    true
  end
  # extend ActiveSupport::Concern
  
  include HancockShrine::BaseUploader

  # def self.inherited(subclass)
  #   # puts 'def inherited(subclass)'
  #   # puts 'HancockUploader < Shrine'
  #   # puts subclass
  #   super(subclass)
  # end

  include ::HancockShrine::Uploadable::UploadEndpoint
  
end
