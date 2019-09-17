module HancockShrine::Uploadable
  extend ActiveSupport::Concern
    
  # ALLOWED_TYPES = %w[image/jpeg image/png image/jpg image/pjpeg image/svg image/webp]
  ALLOWED_TYPES = HancockShrine.config.plugin_options[:validation_helpers][:allowed_types]
  # MAX_SIZE      = 20*1024*1024 # 20 MB
  # MAX_SIZE      = 15*1024*1024 # 15 MB
  # MAX_SIZE      = 10*1024*1024 # 10 MB
  MAX_SIZE      = HancockShrine.config.plugin_options[:validation_helpers][:max_size]

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
