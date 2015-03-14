class VideosController < ApplicationController
  def index
    @total_plays = Video.sum(:play_count).to_i
    @videos = Video.all
  end
end
