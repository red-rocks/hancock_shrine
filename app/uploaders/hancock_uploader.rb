class HancockUploader < Shrine
  extend ActiveSupport::Concern
  
  include HancockShrine::BaseUploader

  def self.inherited(subclass)
    puts 'def inherited(subclass)'
    puts 'HancockUploader < Shrine'
    puts subclass
    super(subclass)
  end

end
