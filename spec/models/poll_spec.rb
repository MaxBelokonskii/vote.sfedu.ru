require "rails_helper"

RSpec.describe Poll do
  describe "scopes" do
    describe ".active" do
      it "returns polls where current time is between starts_at and ends_at" do
        active = create(:poll, starts_at: 1.day.ago, ends_at: 1.day.from_now)
        upcoming = create(:poll, starts_at: 1.day.from_now, ends_at: 2.days.from_now)
        past = create(:poll, starts_at: 2.days.ago, ends_at: 1.day.ago)

        expect(Poll.active).to include(active)
        expect(Poll.active).not_to include(upcoming)
        expect(Poll.active).not_to include(past)
      end
    end

    describe ".not_archived" do
      it "excludes archived polls" do
        active = create(:poll)
        archived = create(:poll, archived_at: Time.current)

        expect(Poll.not_archived).to include(active)
        expect(Poll.not_archived).not_to include(archived)
      end
    end
  end

  describe "instance methods" do
    let(:poll) { create(:poll, starts_at: 1.day.ago, ends_at: 1.day.from_now) }

    describe "#current?" do
      it "returns true when poll is active" do
        expect(poll.current?).to be(true)
      end

      it "returns false when poll is in the past" do
        past_poll = create(:poll, starts_at: 2.days.ago, ends_at: 1.day.ago)
        expect(past_poll.current?).to be(false)
      end
    end

    describe "#upcoming?" do
      it "returns true when starts_at is in the future" do
        upcoming = create(:poll, starts_at: 1.day.from_now, ends_at: 2.days.from_now)
        expect(upcoming.upcoming?).to be(true)
      end
    end

    describe "#started?" do
      it "returns true when starts_at is in the past" do
        expect(poll.started?).to be(true)
      end
    end

    describe "#finished?" do
      it "returns true when ends_at is in the past" do
        past_poll = create(:poll, starts_at: 2.days.ago, ends_at: 1.day.ago)
        expect(past_poll.finished?).to be(true)
      end
    end

    describe "#archived?" do
      it "returns true when archived_at is set" do
        poll.update_column(:archived_at, Time.current)
        expect(poll.archived?).to be(true)
      end

      it "returns false when archived_at is nil" do
        expect(poll.archived?).to be(false)
      end
    end

    describe "#student_participated_in_poll?" do
      let(:student) { create(:student) }

      it "returns false when student has not participated" do
        expect(poll.student_participated_in_poll?(student)).to be(false)
      end

      it "returns true when student has participated" do
        Poll::Participation.create!(poll: poll, student: student)
        expect(poll.student_participated_in_poll?(student)).to be(true)
      end
    end
  end
end
