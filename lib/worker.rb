class RunwayWorker
  include Sidekiq::Worker

  def perform
    puts "ALGO"
    Runway.perform
  end
end