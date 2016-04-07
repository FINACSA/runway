require 'yaml'
require 'sidekiq/scheduler'
require './lib/runway'
require './lib/worker'

Sidekiq.configure_server do |config|
  config.average_scheduled_poll_interval = 15
  config.redis = { url: 'redis://localhost:6379/12' }

  config.on(:startup) do
    Sidekiq.schedule = YAML.load_file(File.expand_path("../config/scheduler.yml",__FILE__))
    Sidekiq::Scheduler.enabled = true
    Sidekiq::Scheduler.reload_schedule!
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: 'redis://localhost:6379/12' }
end