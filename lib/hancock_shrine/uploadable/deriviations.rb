module HancockShrine::Uploadable::Deriviations
  extend ActiveSupport::Concern

  included do
  
    plugin :derivation_endpoint,
      secret_key: "123456798",
      prefix:     derivation_endpoint_prefix

  end


  class_methods do

    def derivation_endpoint_prefix
      "upload/derivations/#{hancock_model.name.underscore}/#{hancock_field_name}"
    end

  end

end
  