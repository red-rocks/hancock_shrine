class Shrine
  module Plugins
    # The `hancock_validations` plugin attempts nicer access to :validation_helpers plugin for different storages
    #
    #     plugin :hancock_validations
    
    module HancockValidations

      def self.load_dependencies(uploader, *)
        uploader.plugin :validation_helpers
        # uploader.plugin :default_version, name: :original
      end

      def self.configure(uploader, opts = {})
      end
      

      module AttachmentMethods
        def define_model_methods(name)
          super if defined?(super)

          Shrine::Plugins::ValidationHelpers::DEFAULT_MESSAGES.each do |type, message|
            define_method :"#{name}_error_#{type}" do |*args|
              message.call(*args)
            end
          end

        end
      end


      module AttacherMethods

        def validate_result(result, type, message, *args)
          if result
            true
          else
            _message = record&.try("#{name}_error_#{type}", *args)
            add_error(type, _message || message, *args)
            false
          end
        end

      end


      module AttacherClassMethods
      end

    end

    register_plugin(:hancock_validations, HancockValidations)
  end
end
