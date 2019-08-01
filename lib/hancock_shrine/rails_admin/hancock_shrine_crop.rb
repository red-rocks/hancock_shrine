require 'rails_admin/config/actions'

module RailsAdmin
  module Config
    module Actions
      class HancockShrineCrop < Base
        RailsAdmin::Config::Actions.register(self)

        # Is the action acting on the root level (Example: /admin/contact)
        register_instance_option :root? do
          false
        end

        register_instance_option :collection? do
          false
        end

        # Is the action on an object scope (Example: /admin/team/1/edit)
        register_instance_option :member? do
          true
        end

        register_instance_option :controller do
          proc do
            if params['id'].present?
              begin
                @object = @abstract_model.model.unscoped.find(params['id'])
                
                method_name = params[:name].to_s
                attacher_method_name = "#{method_name}_attacher"
                attacher = @object.try(attacher_method_name)
                
                if @object and attacher.class.module_parent < Shrine
                  [:crop_x, :crop_y, :crop_w, :crop_h].each do |meth|
                    @object.send("#{meth}=", params[meth])
                  end
                  if params[method_name].blank?
                    @object.send("reprocess_#{method_name}")
                  else
                    # puts params[method_name].inspect
                    # puts JSON.parse(params[method_name]).inspect
                    # @object.send("#{method_name}=", JSON.parse(params[method_name]))
                    @object.send("#{method_name}=", params[method_name])
                  end
                end
                
                if @object.save
                  data = @object.send(method_name)
                  data.each_pair { |style, style_data|
                    style_data.data.merge!({
                      url: data.url(style)
                    })
                  }
                  render json: data
                else

                  render json: @object.errors, status: 422
                end
              rescue Exception => ex
                puts 'register_instance_option :controller do'
                puts ex.inspect
                render json: {errors: ["Непредвиденная ошибка", ex.inspect]}, status: 500

              end
            end

          end
        end

        register_instance_option :link_icon do
          'icon-refresh'
        end

        register_instance_option :pjax? do
          false
        end

        register_instance_option :http_methods do
          [:post]
        end

      end
    end
  end
end
