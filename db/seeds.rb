require "SecureRandom"

videos = Array.new

# generate 100 unique video_ids
100.times do
  videos << SecureRandom.uuid
end

# create 100 Videos in the database, each with a unique UUID
videos.each do |uuid|
  video = Video.find_or_create_by(video_uuid: uuid)
  video.update(last_viewed_at: Time.now)
end
