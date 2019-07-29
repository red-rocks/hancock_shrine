module HancockShrine
  include Hancock::PluginConfiguration

  def self.config_class
    Configuration
  end

  class Configuration

    attr_accessor :vips

    attr_accessor :plugins
    attr_accessor :plugin_options

    def initialize
      @vips = !!defined?(::Vips)

      @plugins = %w(
        data_uri
        cached_attachment_data
        restore_cached_data
        remote_url
        remove_attachment
        moving
        store_dimensions
        validation_helpers
        processing
        backgrounding
        cropable
        hancockable
        hancock_versions
        versions
        compatibility
      )
      @plugins.delete 'backgrounding' # TEMP
      # @plugins.delete 'hancock_versions' # TEMP
      @plugins.delete 'hancockable' # TEMP
      

      @plugin_options = {
        saver: {
          opts: {
            quality: 90, strip: true
          }
        },
        remote_url: {
          max_size: 20*1024*1024
        },
        store_dimensions: {
          analyzer: (@vips ? :ruby_vips : :fastimage)
        },
        validation_helpers: {
          allowed_types: %w[image/jpeg image/png image/jpg image/pjpeg image/svg image/webp],
          max_size: 20*1024*1024,
          max_width: 6000,
          max_height: 6000
        }
      }
    end
  end
end
