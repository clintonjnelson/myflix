Myflix::Application.configure do
  config.cache_classes = true

  config.serve_static_assets = true
  config.static_cache_control = "public, max-age=3600"

  config.eager_load = false

  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  config.action_dispatch.show_exceptions = false

  config.action_controller.allow_forgery_protection  = false

  #This is because Capybara uses this instead of localhost, so it will fail the tests otherwise
  config.action_mailer.default_url_options = { host: "127.0.0.1:3005" }
  config.action_mailer.delivery_method = :test  #:test
  config.active_support.deprecation = :stderr
end
