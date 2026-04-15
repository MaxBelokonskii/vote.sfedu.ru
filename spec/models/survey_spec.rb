require "rails_helper"

RSpec.describe Survey do
  let(:user) { create(:user_with_teacher) }

  def build_survey(attrs = {})
    Survey.new({title: "Test", passcode: "test-#{SecureRandom.hex(4)}", user: user, active_until: 2.weeks.from_now}.merge(attrs))
  end

  describe "validations" do
    it "is valid with title, passcode, and user" do
      expect(build_survey).to be_valid
    end

    it "requires title" do
      expect(build_survey(title: nil)).not_to be_valid
    end

    it "requires passcode" do
      expect(build_survey(passcode: nil)).not_to be_valid
    end
  end

  describe "#answered_for?" do
    it "returns false when user has not answered" do
      survey = build_survey
      survey.save!
      expect(survey.answered_for?(user.id)).to be(false)
    end

    it "returns true when user has answered" do
      survey = build_survey
      survey.save!
      question = Survey::Question.create!(survey: survey, text: "Q?")
      option = Survey::Option.create!(survey_question: question, text: "A")
      Survey::Answer.create!(survey: survey, survey_question: question, survey_option: option, user: user)

      expect(survey.answered_for?(user.id)).to be(true)
    end
  end

  describe "nested attributes" do
    it "accepts nested questions" do
      survey = build_survey
      survey.questions.build(text: "Question 1")
      survey.save!
      expect(survey.questions.count).to eq(1)
    end

    it "allows destroying questions" do
      survey = build_survey
      survey.save!
      question = Survey::Question.create!(survey: survey, text: "Q")
      survey.update!(questions_attributes: [{id: question.id, _destroy: "1"}])
      expect(survey.questions.count).to eq(0)
    end
  end
end
