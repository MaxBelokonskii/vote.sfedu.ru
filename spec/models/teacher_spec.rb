require "rails_helper"

RSpec.describe Teacher do
  describe "validations" do
    it "is valid with required attributes" do
      expect(build(:teacher)).to be_valid
    end

    it "requires name" do
      expect(build(:teacher, name: nil)).not_to be_valid
    end

    it "accepts valid snils format (11 digits)" do
      expect(build(:teacher, snils: "12345678901")).to be_valid
    end

    it "rejects invalid snils format" do
      expect(build(:teacher, snils: "123")).not_to be_valid
      expect(build(:teacher, snils: "abcdefghijk")).not_to be_valid
    end

    it "allows blank snils for imported teachers" do
      expect(build(:teacher, snils: nil, origin: :imported)).to be_valid
    end

    it "requires snils for manual teachers" do
      teacher = build(:teacher, :manual, snils: nil)
      expect(teacher).not_to be_valid
      expect(teacher.errors[:snils]).to be_present
    end
  end

  describe "origin" do
    it "defaults to imported" do
      teacher = Teacher.new(name: "X")
      expect(teacher.origin).to eq("imported")
    end

    it "supports manual origin" do
      teacher = build(:teacher, :manual)
      expect(teacher.origin_manual?).to be(true)
      expect(teacher.origin_imported?).to be(false)
    end
  end

  describe "scopes" do
    let!(:active_teacher) { create(:teacher) }
    let!(:deleted_teacher) { create(:teacher, :deleted) }

    it ".active returns non-deleted" do
      expect(Teacher.active).to include(active_teacher)
      expect(Teacher.active).not_to include(deleted_teacher)
    end

    it ".deleted returns soft-deleted" do
      expect(Teacher.deleted).to include(deleted_teacher)
      expect(Teacher.deleted).not_to include(active_teacher)
    end
  end

  describe "#soft_delete!" do
    it "sets deleted_at" do
      teacher = create(:teacher)
      expect { teacher.soft_delete! }.to change { teacher.deleted_at }.from(nil)
    end
  end

  describe "#editable_by_admin?" do
    it "returns true for manual" do
      expect(build(:teacher, :manual)).to be_editable_by_admin
    end

    it "returns false for imported" do
      expect(build(:teacher, origin: :imported)).not_to be_editable_by_admin
    end
  end
end
