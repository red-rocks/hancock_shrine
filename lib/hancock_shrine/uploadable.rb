module HancockShrine::Uploadable
  extend ActiveSupport::Concern

  included do |base|

    include Content

    include Options

    include Styles

    include Plugins

  end

  class_methods do

    def inherited(subclass)
      super(subclass)
    end

  end

end
