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

      module ClassMethods
        def endpoint_name
          # name.underscore
          name.underscore.to_url.underscore
        end
      end


      module AttacherMethods
        def initialize(file: nil, cache: :cache, store: :store, hancock_model: hancock_model, is_image: is_image)
          # puts 'def initialize(file: nil, cache: :cache, store: :store, hancock_model: hancock_model, is_image: is_image)'
          # puts hancock_model.inspect
          # puts is_image.inspect

          @hancock_model = hancock_model
          @is_image = is_image
          super(file: file, cache: cache, store: store)
        end
      end


      module FileMethods

        # override
        def [](*keys)
          keys.map! { |key| 
            (key.is_a?(Symbol) ? key.to_s : key)
          }
          super(keys)
          # if keys.any? { |key| key.is_a?(Symbol) }
          #   fail Error, "Shrine::UploadedFile#[] doesn't accept symbol metadata names. Did you happen to call `record.attachment[:derivative_name]` when you meant to call `record.attachment(:derivative_name)`?"
          # else
          #   super
          # end
        end


        # TODO!!!
        def inline_data
          _data = StringIO.new
          stream(_data)
          _data.rewind
          _data.read
        rescue
          nil
          # self[style].read.force_encoding("UTF-8") rescue ""
          # if queued_for_write[style]
          #   queued_for_write[style].read.force_encoding("UTF-8").html_safe rescue ""
          # elsif !path(style).blank? and File.exists?(path(style))
          #   File.read(path(style)).force_encoding("UTF-8").html_safe rescue ""
          # end
        end

        def base64
          _data = inline_data
          (_data ? Base64.encode64(_data) : "")
        end
        def base64_as_src
          "data:#{content_type};base64,#{base64}" 
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