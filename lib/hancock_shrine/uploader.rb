class HancockShrine::Uploader < Shrine

  include HancockShrine::Uploadable

  def self.inherited(subclass)
    # puts 'def inherited(subclass)'
    # puts 'HancockShrine::Uploader < Shrine'
    # puts subclass
    super(subclass)
  end
  
  # include HancockShrine::Uploadable::InstanceMethods
  # extend HancockShrine::Uploadable::ClassMethods

end
