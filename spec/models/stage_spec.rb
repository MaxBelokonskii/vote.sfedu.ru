require "rails_helper"

RSpec.describe Stage, type: :model do
  subject(:stage) { create(:stage, :with_semester, :with_questions) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(stage).to be_valid
    end

    it "is invalid without starts_at" do
      stage.starts_at = nil
      expect(stage).not_to be_valid
      expect(stage.errors[:starts_at]).to be_present
    end

    it "is invalid without ends_at" do
      stage.ends_at = nil
      expect(stage).not_to be_valid
      expect(stage.errors[:ends_at]).to be_present
    end

    it "is invalid when ends_at is before starts_at" do
      stage.ends_at = stage.starts_at - 1.day
      expect(stage).not_to be_valid
      expect(stage.errors[:ends_at]).to be_present
    end

    it "is invalid when ends_at equals starts_at" do
      stage.ends_at = stage.starts_at
      expect(stage).not_to be_valid
      expect(stage.errors[:ends_at]).to be_present
    end

    it "is invalid without at least one semester" do
      stage.semesters = []
      expect(stage).not_to be_valid
      expect(stage.errors[:semesters]).to be_present
    end

    it "is invalid without at least one question" do
      stage.questions = []
      expect(stage).not_to be_valid
      expect(stage.errors[:questions]).to be_present
    end

    it "is invalid when lower_participants_limit is negative" do
      stage.lower_participants_limit = -1
      expect(stage).not_to be_valid
      expect(stage.errors[:lower_participants_limit]).to be_present
    end

    it "is valid when lower_participants_limit is zero" do
      stage.lower_participants_limit = 0
      expect(stage).to be_valid
    end

    context "when with_scale is true" do
      before { stage.with_scale = true }

      it "is invalid when scale_max equals scale_min" do
        stage.scale_min = 5
        stage.scale_max = 5
        expect(stage).not_to be_valid
        expect(stage.errors[:scale_max]).to be_present
      end

      it "is invalid when scale_max is less than scale_min" do
        stage.scale_min = 8
        stage.scale_max = 5
        expect(stage).not_to be_valid
        expect(stage.errors[:scale_max]).to be_present
      end

      it "is valid when scale_max is greater than scale_min" do
        stage.scale_min = 5
        stage.scale_max = 10
        expect(stage).to be_valid
      end
    end

    context "when with_scale is false" do
      before { stage.with_scale = false }

      it "does not validate scale_max vs scale_min" do
        stage.scale_min = 10
        stage.scale_max = 5
        expect(stage).to be_valid
      end
    end
  end

  describe "scopes" do
    let!(:active_stage) { create(:stage, :with_semester, :with_questions) }
    let!(:deleted_stage) { create(:stage, :with_semester, :with_questions, :deleted) }

    describe ".active" do
      it "returns stages without deleted_at" do
        expect(Stage.active).to include(active_stage)
      end

      it "does not return soft-deleted stages" do
        expect(Stage.active).not_to include(deleted_stage)
      end
    end

    describe ".deleted" do
      it "returns soft-deleted stages" do
        expect(Stage.deleted).to include(deleted_stage)
      end

      it "does not return active stages" do
        expect(Stage.deleted).not_to include(active_stage)
      end
    end
  end

  describe "#soft_delete!" do
    let(:target_stage) { create(:stage, :with_semester, :with_questions) }

    it "sets deleted_at to current time" do
      before = Time.current
      target_stage.soft_delete!
      after = Time.current
      expect(target_stage.reload.deleted_at).to be_between(before, after)
    end

    it "marks the stage as deleted" do
      target_stage.soft_delete!
      expect(target_stage.reload).to be_deleted
    end

    it "removes stage from active scope" do
      target_stage.soft_delete!
      expect(Stage.active).not_to include(target_stage)
    end
  end

  describe "#deleted?" do
    it "returns false when deleted_at is nil" do
      stage.deleted_at = nil
      expect(stage).not_to be_deleted
    end

    it "returns true when deleted_at is set" do
      stage.deleted_at = Time.current
      expect(stage).to be_deleted
    end
  end
end
