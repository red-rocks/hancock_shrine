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
        hancock_validations
        processing
        backgrounding
        cropable
        hancockable
        hancock_versions
        versions
        compatibility
      )
      # @plugins.delete 'validation_helpers' # TEMP

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
          analyzer: (@vips ? :ruby_vips : :fastimage),
          if: :is_image
        },
        cropable: { 
          if: :is_image
        }, 
        hancock_versions: { 
          if: :is_image
        }, 
        versions: { 
          if: :is_image
        }, 
        validation_helpers: {
          allowed_image_types: %w[
            image/jpeg 
            image/png 
            image/jpg 
            image/pjpeg 
            image/svg 
            image/svg+xml
            image/webp
          ],
          allowed_media_types: %w[
            video/mp4
            audio/mp3
            image/gif
            video/x-msvideo
            video/x-matroska
            video/quicktime
          ],
          allowed_types: [
            'application/vnd.oasis.opendocument.text',
            'application/vnd.oasis.opendocument.spreadsheet',
            'application/vnd.oasis.opendocument.presentation',
            'application/vnd.oasis.opendocument.graphics',
          
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'application/vnd.ms-powerpoint',
            'application/vnd.openxmlformats-officedocument.presentationml.presentation',
            'application/msword',
            'application/vnd.ms-word.document.macroenabled.12',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document:',
            'application/vnd.ms-word.template.macroenabled.12',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.template',
            'application/vnd.ms-excel',
            'application/vnd.ms-excel.addin.macroenabled.12',
            'application/x-xliff+xml',
            'application/vnd.ms-excel.sheet.binary.macroenabled.12',
            'application/vnd.ms-excel.sheet.macroenabled.12',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'application/vnd.ms-excel.template.macroenabled.12',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.template',

            # 'md': 'text/markdown',
            # 'markdown': 'text/markdown',
            # 'yaml': 'text/yaml',
            # 'yml': 'text/yaml',
            # 'csv': 'text/csv',
          
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
