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

                derivatives_method_name = "#{method_name}_derivatives"
                update_derivatives_method_name = "#{derivatives_method_name}!"

                # puts '@object.send(method_name) before'
                # puts @object.send(method_name).class
                # puts @object.send(method_name).inspect
                
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
                
                # TODO: ??? maybe no need
                # @object.send(update_derivatives_method_name) if @object.respond_to?(update_derivatives_method_name)
                if @object.save!
                  data = @object.try(derivatives_method_name) || @object.send(method_name) || {}
                  # puts '@object.send(method_name)'
                  # puts data.inspect
                  # puts data.class
                  # # puts data.url
                  # puts 'data.each_pair { |style, style_data|'
                  data.each { |style, style_data|
                    data[style] = if style_data.is_a?(Shrine::UploadedFile)
                    # style_data = if style_data.is_a?(Shrine::UploadedFile)
                      style_data.data.merge({url: style_data.url})
                    else
                      style_data.data.merge({url: data.url(style)})
                    end
                  }
                  # derivatives fix
                  data[:original] ||= @object.send(method_name).as_json.merge({url: @object.send(method_name).url})
                  # puts data.inspect
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
