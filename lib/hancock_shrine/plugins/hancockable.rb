# TEST
class Shrine
  module Plugins
    # The `hancockable` plugin attempts attachments methods
    #
    #     plugin :hancockable
    #
    module Hancockable
      def self.configure(uploader, opts = {})
      end

      module FileMethods

        def inline_data(style=:original)
          if queued_for_write[style]
            queued_for_write[style].read.force_encoding("UTF-8").html_safe rescue ""
          elsif !path(style).blank? and File.exists?(path(style))
            File.read(path(style)).force_encoding("UTF-8").html_safe rescue ""
          end
        end

        def base64(style=:original)
          _data = inline_data(style)
          Base64.encode64(_data) if _data
        end
        def base64_as_src(style=:original)
          _base64 = base64(style)
          "data:#{content_type};base64,#{_base64}" unless _base64.blank?
        end
        

        def svg?
          !!(content_type =~ /svg/)
        end 

        def image?
          svg? or content_type.start_with?("image/")
        end

        def inline_svg
          inline_data if svg?
        end
        
      end
    end

    register_plugin(:hancockable, Hancockable)
  end
end