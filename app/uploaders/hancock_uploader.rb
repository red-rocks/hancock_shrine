# class HancockUploader < Shrine
class HancockUploader < HancockShrine::Uploader
  # extend ActiveSupport::Concern
  
  include HancockShrine::BaseUploader

  # def self.inherited(subclass)
  #   # puts 'def inherited(subclass)'
  #   # puts 'HancockUploader < Shrine'
  #   # puts subclass
  #   super(subclass)
  # end

  puts 'HancockShrine::Uploadable::UploadEndpoint'
  puts (self < HancockShrine::Uploadable::UploadEndpoint).inspect
  include ::HancockShrine::Uploadable::UploadEndpoint
  puts (self < HancockShrine::Uploadable::UploadEndpoint).inspect
  puts 'HancockShrine::Uploadable::UploadEndpoint'
  
end
