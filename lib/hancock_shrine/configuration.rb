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
      # @plugins.delete 'hancockable' # TEMP

      @plugins.delete 'moving' # shrine 3.0

      @plugins.delete 'remove_attachment' # shrine 3.0
      @plugins.delete 'processing' # shrine 3.0
      @plugins.delete 'versions' # shrine 3.0
      @plugins[@plugins.index('hancock_versions')] = 'hancock_derivatives' rescue @plugins << 'processing' << 'remove_attachment' # shrine 4.0
      # @plugins << "changing_derivatives"

      @plugins.compact!

      @plugin_options = {
        saver: {
          opts: {
            quality: 90, strip: true
          }
        },
        remote_url: {
          max_size: 100*1024*1024,
          max_image_size: 20*1024*1024,
        },
        store_dimensions: {
          analyzer: (@vips ? :ruby_vips : :fastimage)
        },
        validation_helpers: {
          allowed_image_types: %w[image/jpeg image/png image/jpg image/pjpeg image/svg image/webp],
          allowed_types: [
            'application/vnd.oasis.opendocument.text',
            'application/vnd.oasis.opendocument.spreadsheet',
            'application/vnd.oasis.opendocument.presentation',
            'application/vnd.oasis.opendocument.graphics',
          
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'application/vnd.ms-powerpoint',
            'application/vnd.openxmlformats-officedocument.presentationml.presentation',
            'application/msword',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document:',
          
            'application/pdf',
            'text/pdf',
            'application/rtf',
            'text/rtf',
          
            'application/zip',
            'application/gzip',
            'application/xml',
            'application/x-rar',
            'application/x-rar-compressed',
            'application/x-tar',
          
            'text/plain',
            'text/html'
          ], # TODO
          max_size: 100*1024*1024,
          max_image_size: 20*1024*1024,
          max_width: 6000,
          max_height: 6000
        }
      }
    end
  end
end
