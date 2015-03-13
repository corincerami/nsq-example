class CreateVideos < ActiveRecord::Migration
  def change
    create_table :videos do |t|
      t.string :video_uuid
      t.decimal :play_count, default: 0
    end

    add_index(:videos, :video_uuid)
  end
end
