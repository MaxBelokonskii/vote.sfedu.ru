require "rails_helper"

RSpec.describe Participation do
  let(:stage) { create(:stage, :with_semester, :with_questions) }
  let(:student) { create(:student) }
  let(:teacher) { create(:teacher) }

  describe "associations" do
    it "belongs to stage, student, and teacher" do
      participation = Participation.create!(stage: stage, student: student, teacher: teacher)

      expect(participation.stage).to eq(stage)
      expect(participation.student).to eq(student)
      expect(participation.teacher).to eq(teacher)
    end
  end

  describe "creation" do
    it "allows multiple participations for different teachers in the same stage" do
      teacher2 = create(:teacher)
      Participation.create!(stage: stage, student: student, teacher: teacher)
      Participation.create!(stage: stage, student: student, teacher: teacher2)

      expect(Participation.where(stage: stage, student: student).count).to eq(2)
    end
  end
end
