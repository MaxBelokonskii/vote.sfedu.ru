class SurveyCloner
  def self.call(survey)
    new(survey).call
  end

  def initialize(survey)
    @survey = survey
  end

  def call
    clone = @survey.dup
    clone.passcode = nil

    @survey.options.each { |option| clone.options << option.dup }

    @survey.questions.each do |question|
      cloned_question = question.dup
      question.options.where(custom: false).each { |option| cloned_question.options << option.dup }
      clone.questions << cloned_question
    end

    clone
  end
end
