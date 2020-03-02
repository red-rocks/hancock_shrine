class HancockShrine::Uploader < Shrine
  
  def self.is_image
    false
  end
  def self.init_plugins?
    false
  end

  include HancockShrine::Uploadable

  # def self.inherited(subclass)
  #   # puts 'def inherited(subclass)'
  #   # puts 'HancockShrine::Uploader < Shrine'
  #   # puts subclass
  #   super(subclass)
  # end
  
  # include HancockShrine::Uploadable::InstanceMethods
  # extend HancockShrine::Uploadable::ClassMethods

  
  
  # # TODO - maybe not need
  # # direct_upload
  # include ::HancockShrine::Uploadable::UploadEndpoint

  # # include ::HancockShrine::Uploadable::Deriviations::Crop

end
