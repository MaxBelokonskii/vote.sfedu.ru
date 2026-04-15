require "rails_helper"

RSpec.describe Poll::Option do
  describe "#proportion" do
    let(:poll) { create(:poll) }
    let(:option_a) { create(:poll_option, poll: poll) }
    let(:option_b) { create(:poll_option, poll: poll) }

    it "returns 0 when there are no answers" do
      expect(option_a.proportion).to eq(0)
    end

    it "calculates percentage of total answers" do
      3.times { Poll::Answer.create!(poll: poll, poll_option: option_a) }
      Poll::Answer.create!(poll: poll, poll_option: option_b)

      expect(option_a.proportion).to eq(75.0)
      expect(option_b.proportion).to eq(25.0)
    end
  end

  describe "associations" do
    it "belongs to poll" do
      poll = create(:poll)
      option = create(:poll_option, poll: poll)
      expect(option.poll).to eq(poll)
    end
  end
end
