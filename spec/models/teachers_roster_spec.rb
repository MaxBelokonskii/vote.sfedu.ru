require "rails_helper"

RSpec.describe TeachersRoster do
  describe "associations" do
    it "belongs to stage and teacher" do
      stage = create(:stage, :with_semester, :with_questions)
      teacher = create(:teacher)
      roster = TeachersRoster.create!(stage: stage, teacher: teacher)

      expect(roster.stage).to eq(stage)
      expect(roster.teacher).to eq(teacher)
    end
  end

  it "is accessible through stage" do
    stage = create(:stage, :with_semester, :with_questions)
    teacher = create(:teacher)
    TeachersRoster.create!(stage: stage, teacher: teacher)

    expect(stage.teachers_rosters.map(&:teacher)).to include(teacher)
  end
end
