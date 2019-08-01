module HancockShrine
  class Engine < ::Rails::Engine

    initializer "JCropper precompile hook", group: :all do |app|
      app.config.assets.precompile += %w(cropper/cropper.js cropper/cropper.css)
    end

  end
end
