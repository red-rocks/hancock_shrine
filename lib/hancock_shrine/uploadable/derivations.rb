module HancockShrine::Uploadable::Deriviations
  extend ActiveSupport::Concern

  included do
  
    plugin :derivation_endpoint,
      secret_key: "123456798",
      prefix:     derivation_endpoint_prefix

  end


  class_methods do

    def derivation_endpoint_prefix(namespace = "upload")
      # "#{namespace}/derivations/#{hancock_model.name.underscore}/#{hancock_field_name}"
      # "#{namespace}/derivations"
      [namespace, "derivations"].reject(&:blank?).join("/")
    end

  end

end
  