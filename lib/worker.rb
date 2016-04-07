class RunwayWorker
  include Sidekiq::Worker

  def perform
    Runway.perform
  end
end