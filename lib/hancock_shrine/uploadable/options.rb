module HancockShrine::Uploadable::Options
  extend ActiveSupport::Concern

  included do

    def max_width
      HancockShrine.config.plugin_options[:validation_helpers][:max_width]
    end
    def max_height
      HancockShrine.config.plugin_options[:validation_helpers][:max_height]
    end


    def saver_opts
      HancockShrine.config.plugin_options[:saver][:opts] || {}
    end

  end

end