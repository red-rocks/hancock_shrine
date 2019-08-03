module HancockShrine
  class Engine < ::Rails::Engine

    initializer "JCropper precompile hook", group: :all do |app|
      app.config.assets.precompile += %w(hancock/shrine.js hancock/shrine.css)
    end

  end
end
