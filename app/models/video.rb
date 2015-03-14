class Video < ActiveRecord::Base
  require "json"
  require 'nsq'

  def self.viewed_recently
    all.select { |video| Time.now - video.last_viewed_at <= 2.minutes }
  end

  Nsq.logger = Logger.new(STDOUT)

  MAX_IN_FLIGHT = 100

  PRODUCER = Nsq::Producer.new(
    nsqd: '127.0.0.1:4150',
    topic: 'playcount',
    channel: 'playcount_channel'
  )

  CONSUMER = Nsq::Consumer.new(
    nsqlookupd: '127.0.0.1:4161',
    topic: 'playcount',
    channel: 'playcount_channel',
    max_in_flight: MAX_IN_FLIGHT
  )

  # this method is simply to mock user activity
  def self.generate_plays(low_vids, high_vids, total_views)
    low_count_vids = self.first(low_vids)
    high_count_vids = self.last(high_vids)

    plays = Array.new
    # generate a random number of plays < 100 for low_count_vids
    low_count_vids.each do |vid|
      rand(5..99).times do
        plays << { video_id: vid.video_uuid }.to_json
      end
    end
    # generate views for high_count_vids randomly until there are 100_000 plays total
    until plays.length == total_views
      plays << { video_id: high_count_vids.sample.video_uuid }.to_json
    end
    plays.shuffle
  end

  # the actions of this method would generally be handled on show action of a video
  def self.queue_plays(plays)
    plays.each { |play| PRODUCER.write(play) }
    PRODUCER.terminate
  end

  def self.plays_from_queue
    msg = CONSUMER.pop
    uuid = JSON.parse(msg.body)["video_id"]
    video = self.find_by(video_uuid: uuid)
    video.update(last_viewed_at: Time.now)
    if video.play_count < 100
      video.increment!(:play_count)
      Nsq.logger.info "Video #{video.video_uuid} play count increased by 1"
    else
      count = Rails.cache.read("#{uuid}") || 0
      Rails.cache.write("#{uuid}", count + 1)
      Nsq.logger.info "Video #{uuid} written to cache with value #{count + 1}"
    end
    msg.finish
  end
end
