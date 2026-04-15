require "rails_helper"

RSpec.describe Poll::Participation do
  describe "associations" do
    it "belongs to poll and student" do
      poll = create(:poll)
      student = create(:student)
      participation = Poll::Participation.create!(poll: poll, student: student)

      expect(participation.poll).to eq(poll)
      expect(participation.student).to eq(student)
    end
  end
end
