module HancockShrine::Uploadable::Styles
  extend ActiveSupport::Concern

  included do

    def get_styles(context, action = :upload)
      name = context[:field_name].to_s
      styles_method = name + "_styles"

      if context[:record].method(styles_method).arity == 1
        context[:record].send(styles_method, action)
      else
        context[:record].send(styles_method)
      end
    end

    def resize_opts_default
      {sharpen: false, size: :down}
    end


    def process_style(pipeline:, style_name:, style_opts:, io:, context:)

      opts = {pipeline: pipeline, style_name: style_name, style_opts: style_opts, io: io, context: context}
      pipeline = pre_process_style(opts)

      if style_opts.is_a?(String)
        style_opts = {
          geometry: style_opts
        }
      end

      # https://github.com/thoughtbot/paperclip/blob/6661480c5b321709ad44c7ef9572d7f908857a9d/lib/paperclip/geometry_parser_factory.rb
      if geometry = style_opts[:geometry]
        if actual_match = geometry.match(/\b(\d*)x?(\d*)\b(?:,(\d?))?(\@\>|\>\@|[\>\<\#\@\%^!])?/i)
          width = actual_match[1].to_i
          height = actual_match[2].to_i
          orientation = actual_match[3]
          modifier = actual_match[4]

          # https://github.com/thoughtbot/paperclip/blob/6661480c5b321709ad44c7ef9572d7f908857a9d/lib/paperclip/geometry.rb
          ### TODO; may be not 'resize_to_limit'
          pipeline = case modifier
          when '!', '#'
            pipeline.resize_to_fill(width, height, resize_opts_default)
          when '>'
            pipeline.resize_to_limit(width, height, resize_opts_default)
          when '<'
            pipeline.resize_to_limit(width, height, resize_opts_default)
          else
            pipeline.resize_to_limit(width, height, resize_opts_default)
          end
        end
      end

      if format = style_opts[:format]
        pipeline = pipeline.convert(format)
      end
      
      opts = {pipeline: pipeline, style_name: style_name, style_opts: style_opts, io: io, context: context}
      pipeline = post_process_style(opts)

      pipeline.call!
    end
    def pre_process_style(pipeline:, style_name:, style_opts:, io:, context:)
      pipeline
    end
    def post_process_style(pipeline:, style_name:, style_opts:, io:, context:)
      pipeline
    end

  end
end
