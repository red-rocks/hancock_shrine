class HancockUploader < Shrine
  extend ActiveSupport::Concern
  
  include HancockShrine::BaseUploader

end
