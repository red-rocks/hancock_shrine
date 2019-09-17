module HancockShrine::Uploadable::UploadEndpoint
  extend ActiveSupport::Concern

  included do

    include HancockShrine::Uploader::Content

    plugin :upload_endpoint, upload_context: ->(request) {
      params = request.params.with_indifferent_access
      context = {}
      id = params[:id]
      unless id.blank?
        context[:record] ||= hancock_model.find(id)
      else
        context[:model] ||= hancock_model unless context[:record]
        context[:name] ||= hancock_field_name
      end

      context[:metadata] = {"crop" => {}}
      crop_param_names = [:crop_x, :crop_y, :crop_w, :crop_h]
      if crop_param_names.all? { |param| params[param].present? and !params[param].blank? and params[param] != "null"  }
        crop_param_names.each do |param|
          context[:metadata]["crop"].merge!({
            "#{param}".to_sym => params[param].to_i
          })
        end
      end
      context
    }, url: ->(object, request) {
      crop = (object.metadata["crop"] || object.metadata[:crop])
      (crop.blank? ? object.url : object.derivation_url(:crop, crop[:crop_x], crop[:crop_y], crop[:crop_w], crop[:crop_h]))
    }

  end

end
  