
if Rails.env.development?
  Sidekiq.configure_server do |config|
    config.redis = { url: "redis://localhost:6379/{{DB}}" }
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: "redis://localhost:6379/{{DB}}" }
  end
end

if Rails.env.development?
  Sidekiq.configure_server do |config|
    config.logger = Logger.new(Rails.root.join("log/sidekiq_development.log"))
    config.logger.level = Logger::DEBUG
  end
elsif Rails.env.test?
  Sidekiq.configure_server do |config|
    config.logger = Logger.new(Rails.root.join("log/sidekiq_test.log"))
    config.logger.level = Logger::DEBUG
  end
end
