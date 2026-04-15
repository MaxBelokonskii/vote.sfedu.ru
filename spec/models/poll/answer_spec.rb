require "rails_helper"

RSpec.describe Poll::Answer do
  describe "associations" do
    it "belongs to poll and poll_option" do
      poll = create(:poll, :with_options, options_count: 1)
      option = poll.options.first
      answer = Poll::Answer.create!(poll: poll, poll_option: option)

      expect(answer.poll).to eq(poll)
      expect(answer.poll_option).to eq(option)
    end
  end
end
