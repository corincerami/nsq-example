# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

task queue_plays: :environment do
  Video.generate_plays.each do |video_uuid|
    Video::PRODUCER.write(video_uuid)
    uuid = JSON.parse(video_uuid)["video_id"]
    video = Video.find_by(video_uuid: uuid)
    video.update(last_viewed_at: Time.now)
    Nsq.logger.info "#{video_uuid} written to NSQ"
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
    videos = Video.viewed_recently
    update_values = Hash.new
    videos.each do |vid|
      update_values[vid.video_uuid] = Rails.cache.read("#{vid.video_uuid}") || 0
      Rails.cache.delete("#{vid.video_uuid}")
    end
    if update_values.length > 0
      sql = "UPDATE videos SET play_count = CASE video_uuid "
      update_values.each do |video_uuid, count|
          vid = Video.find_by(video_uuid: video_uuid)
          if vid
            sql += "WHEN '#{video_uuid}' THEN #{vid.play_count.to_i + count} "
          end
      end
      sql += "END"
      ActiveRecord::Base.connection.execute(sql)
    end
end
