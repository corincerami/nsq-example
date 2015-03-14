# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

task queue_plays: :environment do
  Video.generate_plays.each do |play|
    uuid = JSON.parse(play)["video_id"]
    Video::PRODUCER.write(play)
  end
  # this task won't run properly without this pry!
  # what???
  binding.pry
end

task plays_from_queue: :environment do
  while true
    msg = Video::CONSUMER.pop
    uuid = JSON.parse(msg.body)["video_id"]
    video = Video.find_by(video_uuid: uuid)
    video.update(last_viewed_at: Time.now)
    if video.play_count < 100
      video.increment!(:play_count)
    else
      count = Rails.cache.read("#{uuid}") || 0
      Rails.cache.write("#{uuid}", count + 1)
    end
    msg.finish
  end
end

task plays_from_cache: :environment do
  while true
    Video.viewed_recently.each do |video|
      count = Rails.cache.read("#{video.video_uuid}") || 0
      if count >= 99 || Time.now - video.updated_at >= 60
        video.increment!(:play_count, by = (count + 1))
        Rails.cache.delete("#{video.video_uuid}")
      end
    end
  end
end
