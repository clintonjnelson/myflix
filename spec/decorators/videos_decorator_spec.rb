require 'spec_helper'

describe VideoDecorator do
  context "for a video without a rating" do
    it "returns a string that the video is not yet rated" do
      monk = Fabricate(:video)
      rating = monk.decorator.display_rating
      expect(rating).to include("not yet rated")
    end
  end
  context "for a video with a rating" do
    it "returns a string including the average rating of the video" do
      monk = Fabricate(:video)
      review1 = Fabricate(:review, video: monk, rating: 3, user: Fabricate(:user))
      review2 = Fabricate(:review, video: monk, rating: 5, user: Fabricate(:user))
      rating = monk.decorator.display_rating
      expect(rating).to include("4.0/5.0")
    end
  end
end
