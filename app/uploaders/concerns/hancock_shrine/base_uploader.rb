module HancockShrine::BaseUploader
  extend ActiveSupport::Concern
  
  included do
    include HancockShrine::Uploadable
  end

end
