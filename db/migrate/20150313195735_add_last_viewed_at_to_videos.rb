class AddLastViewedAtToVideos < ActiveRecord::Migration
  def change
    add_column :videos, :last_viewed_at, :datetime, default: Time.now
  end
end
