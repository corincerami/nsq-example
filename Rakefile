# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

task queue_plays: :environment do
  Video.generate_plays(20, 80, 100_000).each do |play|
    Video::PRODUCER.write(play)
    Nsq.logger.info "#{play} written to NSQ"
  end
  # this rake task terminates early without this binding...
  # i have no idea why adding this in making it work
  binding.pry
end

task plays_from_queue: :environment do
  while true
    Video.plays_from_queue
  end
end

task plays_from_cache: :environment do
  while true
    Video.viewed_recently.each do |video|
      count = Rails.cache.read("#{video.video_uuid}") || 0
      if count >= 99 || Time.now - video.updated_at >= 60
        Rails.cache.delete("#{video.video_uuid}")
        video.increment!(:play_count, by = (count + 1))
        Nsq.logger.info "Video #{video.video_uuid} play count incremented by #{count + 1}"
      end
    end
  end
end
