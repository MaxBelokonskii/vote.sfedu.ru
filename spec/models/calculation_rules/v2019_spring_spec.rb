require "rails_helper"

RSpec.describe CalculationRules::V2019Spring do
  let(:stage) { create(:stage, :with_semester, :with_questions, questions_count: 2, lower_participants_limit: 0, with_scale: false, with_truncation: false) }
  let(:teacher) { create(:teacher) }
  let(:questions) { stage.questions.order(:id) }

  def create_answer(question, ratings)
    answer = Answer.create!(question: question, stage: stage, teacher: teacher)
    answer.update_column(:ratings, ratings)
    answer
  end

  def create_participation
    create(:student).tap do |student|
      Participation.create!(stage: stage, student: student, teacher: teacher)
    end
  end

  describe "#call" do
    context "with no answers" do
      it "returns zero ratings" do
        result = described_class.new(teacher, stage).call
        expect(result[:participations_count]).to eq(0)
        expect(result[:mean_rating_of_stage]).to eq(0.0)
      end
    end

    context "with answers" do
      before do
        # Question 1: [3, 0, 0, 7, 2] → (3*1 + 7*4 + 2*5) / 12 = 41/12 ≈ 3.4167
        create_answer(questions[0], [3, 0, 0, 7, 2, 0, 0, 0, 0, 0])
        # Question 2: [0, 0, 5, 5, 0] → (5*3 + 5*4) / 10 = 35/10 = 3.5
        create_answer(questions[1], [0, 0, 5, 5, 0, 0, 0, 0, 0, 0])
        3.times { create_participation }
      end

      it "calculates participations_count" do
        result = described_class.new(teacher, stage).call
        expect(result[:participations_count]).to eq(3)
      end

      it "calculates mean_rating_of_stage as average of question ratings" do
        result = described_class.new(teacher, stage).call
        # (3.4167 + 3.5) / 2 ≈ 3.4583
        expect(result[:mean_rating_of_stage]).to be_within(0.01).of(3.458)
      end

      it "returns rating_by_questions with correct structure" do
        result = described_class.new(teacher, stage).call
        expect(result[:rating_by_questions].size).to eq(2)
        expect(result[:rating_by_questions].first).to include(:question, :rating_before_limitation_check, :rating)
      end
    end
  end

  describe "calculate_question_rating_for" do
    subject { described_class.new(teacher, stage).send(:calculate_question_rating_for, ratings) }

    context "with all zeros" do
      let(:ratings) { [0, 0, 0, 0, 0] }
      it { is_expected.to eq(0.0) }
    end

    context "with uniform distribution" do
      let(:ratings) { [2, 2, 2, 2, 2] }
      # (2*1 + 2*2 + 2*3 + 2*4 + 2*5) / 10 = 30/10 = 3.0
      it { is_expected.to eq(3.0) }
    end

    context "with all votes on max" do
      let(:ratings) { [0, 0, 0, 0, 10] }
      # 10*5 / 10 = 5.0
      it { is_expected.to eq(5.0) }
    end

    context "with single voter on min" do
      let(:ratings) { [1, 0, 0, 0, 0] }
      # 1*1 / 1 = 1.0
      it { is_expected.to eq(1.0) }
    end
  end

  describe "respondents_limitation_check" do
    context "when stage has lower_participants_limit" do
      let(:stage) { create(:stage, :with_semester, :with_questions, questions_count: 1, lower_participants_limit: 10, with_scale: false, with_truncation: false) }

      it "returns 0 when respondents below limit" do
        create_answer(questions[0], [3, 2, 0, 0, 0, 0, 0, 0, 0, 0]) # 5 respondents < 10
        result = described_class.new(teacher, stage).call
        expect(result[:rating_by_questions].first[:rating]).to eq(0)
      end

      it "returns rating when respondents at or above limit" do
        create_answer(questions[0], [3, 2, 0, 0, 5, 0, 0, 0, 0, 0]) # 10 respondents
        result = described_class.new(teacher, stage).call
        expect(result[:rating_by_questions].first[:rating]).to be > 0
      end
    end
  end

  describe "truncation (outlier removal)" do
    let(:stage) { create(:stage, :with_semester, :with_questions, questions_count: 1, lower_participants_limit: 0, with_scale: false, with_truncation: true, lower_truncation_percent: 10, upper_truncation_percent: 10) }

    it "removes outliers from ratings" do
      # 20 respondents: 2 on score 1, 16 on score 5, 2 on score 10
      # 10% of 20 = 2, so remove 2 lowest (score 1) and 2 highest (score 10)
      # After truncation: 16 votes on score 5 → avg = 5.0
      create_answer(questions[0], [2, 0, 0, 0, 16, 0, 0, 0, 0, 2])
      result = described_class.new(teacher, stage).call
      relaxed = result[:rating_by_questions].first[:relaxed_rating_before_limitation_check]
      expect(relaxed).to eq(5.0)
    end

    it "includes relaxed_rating keys when truncation enabled" do
      create_answer(questions[0], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
      result = described_class.new(teacher, stage).call
      expect(result[:rating_by_questions].first).to include(:relaxed_rating, :relaxed_rating_before_limitation_check)
    end
  end

  describe "scale_rating" do
    let(:stage) { create(:stage, :with_semester, :with_questions, questions_count: 1, lower_participants_limit: 0, with_scale: true, with_truncation: false, scale_min: 6, scale_max: 10) }

    it "maps mean_rating to scale" do
      create_answer(questions[0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 10]) # avg = 10.0
      result = described_class.new(teacher, stage).call
      expect(result[:final_rating_of_stage]).to be_a(Integer)
      expect(result[:final_rating_of_stage]).to be >= 0
    end

    it "returns mean_rating when scale disabled" do
      no_scale_stage = create(:stage, :with_semester, :with_questions, questions_count: 1, lower_participants_limit: 0, with_scale: false, with_truncation: false)
      q = no_scale_stage.questions.first
      answer = Answer.create!(question: q, stage: no_scale_stage, teacher: teacher)
      answer.update_column(:ratings, [0, 0, 0, 0, 0, 0, 0, 0, 0, 10])
      result = described_class.new(teacher, no_scale_stage).call
      expect(result[:mean_rating_of_stage]).to eq(10.0)
      expect(result[:final_rating_of_stage]).to eq(result[:mean_rating_of_stage])
    end
  end

  describe ".recalculate_scale_ladder!" do
    let(:stage) { create(:stage, :with_semester, :with_questions, scale_min: 6, scale_max: 10, with_scale: true) }

    it "returns an array of ranges" do
      ladder = described_class.recalculate_scale_ladder!(stage: stage)
      expect(ladder).to be_an(Array)
      expect(ladder).to all(be_a(Range))
    end

    it "covers the full scale range" do
      ladder = described_class.recalculate_scale_ladder!(stage: stage)
      expect(ladder.first.begin).to eq(stage.scale_min.to_f)
    end
  end
end
