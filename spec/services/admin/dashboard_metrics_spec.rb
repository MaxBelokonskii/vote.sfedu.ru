require "rails_helper"

RSpec.describe Admin::DashboardMetrics do
  describe "#call" do
    subject(:metrics) { described_class.new.call }

    it "returns a hash with all expected keys" do
      expect(metrics).to include(
        :kpi, :current_stage, :polls, :surveys,
        :participation_trend, :teacher_kinds, :data_quality, :user_activity
      )
    end

    describe "kpi" do
      it "includes student and teacher counts" do
        create(:student)
        create(:teacher)

        result = described_class.new.call[:kpi]
        expect(result[:students_count]).to be >= 1
        expect(result[:teachers_count]).to be >= 1
      end

      it "includes students_participated with stage_active flag" do
        result = described_class.new.call[:kpi][:students_participated]
        expect(result).to include(:count, :total, :stage_active)
      end
    end

    describe "current_stage" do
      it "returns nil when no active stage" do
        expect(described_class.new.call[:current_stage]).to be_nil
      end

      it "returns stage data when active stage exists" do
        stage = create(:stage, :with_semester, :with_questions, starts_at: 1.day.ago, ends_at: 1.day.from_now)

        result = described_class.new.call[:current_stage]
        expect(result).to include(:id, :starts_at, :ends_at, :participations_count, :by_faculty)
        expect(result[:id]).to eq(stage.id)
      end
    end

    describe "participation_trend" do
      it "returns 31 days of data" do
        trend = described_class.new.call[:participation_trend]
        expect(trend.size).to eq(31)
        expect(trend.first).to include(:date, :count)
      end

      it "fills gaps with zeros" do
        trend = described_class.new.call[:participation_trend]
        expect(trend.map { |t| t[:count] }).to all(be >= 0)
      end
    end

    describe "teacher_kinds" do
      it "returns counts by kind" do
        create(:teacher, kind: :common)

        kinds = described_class.new.call[:teacher_kinds]
        expect(kinds).to include(:common, :physical_education, :foreign_language)
        expect(kinds[:common]).to be >= 1
      end
    end

    describe "data_quality" do
      it "returns a list of checks" do
        checks = described_class.new.call[:data_quality]
        expect(checks).to be_an(Array)
        expect(checks.first).to include(:label, :count, :level)
      end
    end

    describe "user_activity" do
      it "returns sign-in counts" do
        activity = described_class.new.call[:user_activity]
        expect(activity).to include(:sign_ins_7d, :sign_ins_30d, :total_users)
      end
    end

    describe "polls" do
      it "returns empty array when no active polls" do
        expect(described_class.new.call[:polls]).to eq([])
      end

      it "returns active poll summaries" do
        create(:poll, :with_options, options_count: 2, starts_at: 1.day.ago, ends_at: 1.day.from_now)

        polls = described_class.new.call[:polls]
        expect(polls.size).to eq(1)
        expect(polls.first).to include(:id, :name, :total_votes, :top_options)
      end
    end

    describe "surveys" do
      it "returns recent surveys" do
        user = create(:user_with_teacher)
        Survey.create!(title: "Test Survey", passcode: "test-123", user: user, active_until: 2.weeks.from_now)

        surveys = described_class.new.call[:surveys]
        expect(surveys.size).to be >= 1
        expect(surveys.first).to include(:title, :passcode, :respondents_count)
      end
    end
  end

  describe ".call" do
    it "caches the result" do
      result1 = described_class.call
      result2 = described_class.call
      expect(result1).to eq(result2)
    end
  end
end
