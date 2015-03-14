require "rails_helper"

RSpec.describe Video do
  describe "generate_plays" do
    it "creates mock video play events" do
      low_vid_1 = FactoryGirl.create(:video)
      low_vid_2 = FactoryGirl.create(:video)
      high_vid_1 = FactoryGirl.create(:video)
      high_vid_2 = FactoryGirl.create(:video)
      plays = Video.generate_plays(2, 2, 1000)

      expect(plays.length).to eq(1000)
    end
  end

  describe "queue" do
    before(:all) do
      @low_vid_1 = FactoryGirl.create(:video)
      @low_vid_2 = FactoryGirl.create(:video)
      @high_vid_1 = FactoryGirl.create(:video)
      @high_vid_2 = FactoryGirl.create(:video)
      @plays = Video.generate_plays(2, 2, 1000)

      Video.queue_plays(@plays)
    end

    it "queues the play events" do
      Video::CONSUMER
      expect(Video::PRODUCER.connected?).to eq(false)
      expect(Video::CONSUMER.size).to eq(100)
    end

    it "published messages from the consumer" do
      1000.times do
        Video.plays_from_queue
      end
      Video::CONSUMER
      expect(Video::CONSUMER.size).to eq(0)
      expect(@low_vid_1.play_count.to_i).to be < 100
      expect(@high_vid_1.play_count.to_i).to be > 100
    end
  end
end
