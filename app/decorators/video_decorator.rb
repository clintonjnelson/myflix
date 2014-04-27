class VideoDecorator
  extend Forwardable  #forwardable is in the standard library
  def_delegators :video, :average_rating

  attr_reader :video
  def initialize(video)
    @video = video
  end

  def display_rating
    @video.average_rating.nil? ? "Rating: (not yet rated)" : "Rating: #{@video.average_rating}/5.0"
  end
end
