require "rails_helper"

RSpec.describe Question do
  describe "validations" do
    it "is valid with text and max_rating" do
      expect(build(:question)).to be_valid
    end

    it "requires text" do
      expect(build(:question, text: nil)).not_to be_valid
    end

    it "requires text to be present (not blank)" do
      expect(build(:question, text: "")).not_to be_valid
    end

    it "requires max_rating to be a positive integer" do
      expect(build(:question, max_rating: 0)).not_to be_valid
      expect(build(:question, max_rating: -1)).not_to be_valid
    end

    it "rejects non-integer max_rating" do
      expect(build(:question, max_rating: 5.5)).not_to be_valid
    end

    it "accepts valid max_rating" do
      expect(build(:question, max_rating: 10)).to be_valid
      expect(build(:question, max_rating: 1)).to be_valid
    end
  end

  describe "#used_in_stages?" do
    it "returns false when question is not in any stage" do
      question = create(:question)
      expect(question.used_in_stages?).to be(false)
    end

    it "returns true when question is in a stage" do
      stage = create(:stage, :with_semester, :with_questions, questions_count: 1)
      question = stage.questions.first
      expect(question.used_in_stages?).to be(true)
    end
  end

  describe "associations" do
    it "has_and_belongs_to_many stages" do
      stage = create(:stage, :with_semester, :with_questions, questions_count: 1)
      question = stage.questions.first
      expect(question.stages).to include(stage)
      expect(stage.questions).to include(question)
    end
  end
end
