class Video < ActiveRecord::Base
  require "json"
  require 'nsq'

  def self.viewed_recently
    all.select { |video| Time.now - video.last_viewed_at <= 5.minutes }
  end

  Nsq.logger = Logger.new(STDOUT)

  PRODUCER = Nsq::Producer.new(
    nsqd: '127.0.0.1:4150',
    topic: 'playcount',
    channel: 'playcount_channel'
  )

  CONSUMER = Nsq::Consumer.new(
    nsqlookupd: '127.0.0.1:4161',
    topic: 'playcount',
    channel: 'playcount_channel',
    max_in_flight: 100
  )

  # this method is simply to mock user activity
  def self.generate_plays
    low_count_vids = self.first(20)
    high_count_vids = self.last(80)

    plays = Array.new
    # generate a random number of plays < 100 for low_count_vids
    low_count_vids.each do |vid|
      rand(5..99).times do
        plays << { video_id: vid.video_uuid }.to_json
      end
    end
    # generate views for high_count_vids randomly until there are 100_000 plays total
    until plays.length == 100_000
      plays << { video_id: high_count_vids.sample.video_uuid }.to_json
    end
    plays.shuffle
  end
end
