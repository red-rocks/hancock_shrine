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
                # TODO
                @object = @abstract_model.model.unscoped.find(params['id']) rescue @abstract_model.model.find(params['id'])
                
                method_name = params[:name].to_s
                attacher_method_name = "#{method_name}_attacher"
                attacher = @object.try(attacher_method_name)
                
                derivatives_method_name = "#{method_name}_derivatives"
                update_derivatives_method_name = "#{derivatives_method_name}!"
                
                if @object&.respond_to?(update_derivatives_method_name)
                  opts = {
                    crop: {
                      crop_x: params[:crop_x],
                      crop_y: params[:crop_y],
                      crop_w: params[:crop_w],
                      crop_h: params[:crop_h]
                    }
                  }
                  processed = object.try(update_derivatives_method_name, opts)

                elsif @object and attacher.class.module_parent < Shrine
                  [:crop_x, :crop_y, :crop_w, :crop_h].each do |meth|
                    @object.send("#{meth}=", params[meth])
                  end
                  processed = if params[method_name].blank?
                    @object.send("reprocess_#{method_name}")
                  else
                    # puts params[method_name].inspect
                    # puts JSON.parse(params[method_name]).inspect
                    # @object.send("#{method_name}=", JSON.parse(params[method_name]))
                    @object.send("#{method_name}=", params[method_name])
                    @object.try(update_derivatives_method_name)
                  end
                end


                # TODO: ??? maybe no need
                # @object.send(update_derivatives_method_name) if @object.respond_to?(update_derivatives_method_name)
                # if @object.save!
                # if @object.try(update_derivatives_method_name) or @object.save!
                # puts "res = @object.try(update_derivatives_method_name)"
                # puts res = @object.try(update_derivatives_method_name)
                # puts res2 = res or @object.save!
                # if res2
                if processed and @object.save!
                
                  data = @object.try(derivatives_method_name) || @object.try(method_name) || {}
                  
                  data.each { |style, style_data|
                    data[style] = if style_data.is_a?(Shrine::UploadedFile)
                    # style_data = if style_data.is_a?(Shrine::UploadedFile)
                      style_data.data.merge({url: ActionController::Base.helpers.asset_url(style_data.url)})
                    else
                      style_data.data.merge({url: ActionController::Base.helpers.asset_url(data.url(style))})
                    end
                  }
                  # derivatives fix
                  data[:original] ||= @object.send(method_name).as_json.merge({url: ActionController::Base.helpers.asset_url(@object.send(method_name).url)})
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
