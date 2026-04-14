require "rails_helper"

RSpec.describe Answer do
  let(:stage) { create(:stage, :with_semester, :with_questions, questions_count: 1) }
  let(:teacher) { create(:teacher) }
  let(:question) { stage.questions.first }

  describe "initialization" do
    it "sets ratings to array of zeros on create" do
      answer = Answer.create!(question: question, stage: stage, teacher: teacher)
      expect(answer.ratings).to eq([0] * question.max_rating)
      expect(answer.ratings.size).to eq(question.max_rating)
    end

    it "creates all-zero ratings matching max_rating length" do
      q = create(:question, max_rating: 5)
      stage.questions << q
      answer = Answer.create!(question: q, stage: stage, teacher: teacher)
      expect(answer.ratings).to eq([0, 0, 0, 0, 0])
    end
  end

  describe "associations" do
    it "belongs to question, stage, and teacher" do
      answer = Answer.create!(question: question, stage: stage, teacher: teacher)
      expect(answer.question).to eq(question)
      expect(answer.stage).to eq(stage)
      expect(answer.teacher).to eq(teacher)
    end
  end
end
