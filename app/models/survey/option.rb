class Survey
  class Option < ApplicationRecord
    self.table_name = "survey_options"

    belongs_to :survey_question, class_name: "Survey::Question"
    has_many :answers, class_name: "Survey::Answer", foreign_key: :survey_option_id, dependent: :destroy

    validates :text, presence: true
  end
end
