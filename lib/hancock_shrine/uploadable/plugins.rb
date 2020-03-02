module HancockShrine::Uploadable::Plugins
  extend ActiveSupport::Concern
    
  # ALLOWED_TYPES = %w[image/jpeg image/png image/jpg image/pjpeg image/svg image/webp]
  ALLOWED_IMAGE_TYPES = HancockShrine.config.plugin_options[:validation_helpers][:allowed_image_types]
  ALLOWED_TYPES       = HancockShrine.config.plugin_options[:validation_helpers][:allowed_types]
  # MAX_SIZE      = 20*1024*1024 # 20 MB
  # MAX_SIZE      = 15*1024*1024 # 15 MB
  # MAX_SIZE      = 10*1024*1024 # 10 MB
  MAX_SIZE        = HancockShrine.config.plugin_options[:validation_helpers][:max_size]
  MAX_IMAGE_SIZE  = HancockShrine.config.plugin_options[:validation_helpers][:max_image_size]

  included do |base|

    init_plugins(base)

  end

  class_methods do

    def inherited(subclass)
      super(subclass)
      subclass.init_plugins(subclass)  if superclass.try(:init_plugins?)
    end

  
    def init_plugins(base)
      HancockShrine.config.plugins.each do |plugin_name|
        plugin_name = plugin_name.to_sym
        plugin_options = HancockShrine.config.plugin_options[plugin_name] || {}

        if_condition = plugin_options.delete(:if)
        if if_condition 
          next if if_condition == :is_image and !is_image
        end

        unless_condition = plugin_options.delete(:unless)
        if unless_condition 
          next if unless_condition == :is_image and is_image
        end
        
        begin
          # puts "#{plugin_name} with_options"
          plugin plugin_name, plugin_options
        rescue Exception => ex
          # puts ex.inspect
    
          # puts "#{plugin_name} solo"
          plugin plugin_name
        end

        if plugin_name == :validation_helpers or plugin_name == :hancock_validations
          if defined?(base) and base and defined?(base::Attacher) and base::Attacher
            base::Attacher.validate do
              if @is_image
                validate_max_size base::MAX_IMAGE_SIZE if base::MAX_IMAGE_SIZE
              else
                validate_max_size base::MAX_SIZE if base::MAX_SIZE
              end
              
              # TODO
              if @is_image
                unless base::ALLOWED_IMAGE_TYPES.blank?
                  if validate_mime_type(base::ALLOWED_IMAGE_TYPES)
                    if file["width"] and store.max_width
                    # if store.max_width
                      validate_max_width store.max_width
                    end
                    if file["height"] and store.max_height
                    # if store.max_height
                      validate_max_height store.max_height
                    end
                  end
                end

              else
                unless base::ALLOWED_TYPES.blank?
                  validate_mime_type(base::ALLOWED_TYPES)
                end
              end
              
            end
          end
        elsif plugin_name == :processing
          class_eval <<-RUBY

            def hancock_processing(action, io, context)
              if action.to_sym == :upload
                context[:location] ||= hancock_location(io, context)
                return io
              end
              original, versions = get_data_from(io, context) do |original, versions|
                begin

                  pipeline = get_pipeline(original)
                  if pipeline
                    versions[:compressed] = pipeline.convert!(nil)
                    pipeline = cropping(pipeline, io, context)

                    case action.to_sym
                    when :store, :recache
                      styles = get_styles(context, action.to_sym)

                      styles.each_pair do |style_name, style_opts|
                        opts = {
                          pipeline: pipeline,
                          style_name: style_name,
                          style_opts: style_opts, 
                          io: io, 
                          context: context
                        }
                        versions[style_name] = process_style(opts)
                      end
                    else
                    end
                  end
                rescue
                end
                versions
              end
              versions.compact
            end
          RUBY
          process(:store) do |io, context|
            hancock_processing(:store, io, context)
          end
          process(:recache) do |io, context|
            hancock_processing(:recache, io, context)
          end
          process(:upload) do |io, context|
            hancock_processing(:upload, io, context)
          end
        
        elsif plugin_name == :hancock_derivatives
          class_eval <<-RUBY
            # Attacher.derivatives :hancock_processor do |original|
            Attacher.derivatives_processor do |original, crop: nil|
              
              opts = { crop: crop }

              self.hancock_derivatives(original, record, name, context, opts)
            end
          RUBY
        end

      end


    end
  
  end

end
  