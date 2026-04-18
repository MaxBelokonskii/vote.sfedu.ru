require "rails_helper"
require "csv"

describe Teachers::AsAdmin::ImportFromFile do
  let(:tempfile) do
    file = Tempfile.new(["teachers", ".csv"])
    CSV.open(file.path, "w") do |csv|
      csv << ["ФИО", "СНИЛС", "ID в 1С"]
      rows.each { |r| csv << r }
    end
    file
  end

  after { tempfile.close!; tempfile.unlink rescue nil } # rubocop:disable Style/RescueModifier

  subject(:result) do
    described_class.call(file_path: tempfile.path, extension: "csv")
  end

  context "with valid rows" do
    let(:rows) do
      [
        ["Иванов Иван Иванович", "11223344595", ""],
        ["Петров Пётр Петрович", "15778846842", "EXT-1"]
      ]
    end

    it "creates teachers" do
      expect { subject }.to change { Teacher.count }.by(2)
    end

    it "returns created list" do
      expect(result.created.size).to eq(2)
      expect(result.failed).to be_empty
      expect(result.skipped).to be_empty
    end

    it "sets manual origin and default kind" do
      result
      teacher = Teacher.find_by(name: "Иванов Иван Иванович")
      expect(teacher.origin_manual?).to be true
      expect(teacher.kind).to eq("common")
    end
  end

  context "with snils separators" do
    let(:rows) { [["Сидоров С. С.", "112-233-445 95", "EXT-2"]] }

    it "normalizes snils" do
      expect(result.created.size).to eq(1)
      expect(result.created.first.snils).to eq("11223344595")
    end
  end

  context "with duplicate snils" do
    let!(:existing) { create(:teacher, snils: "11223344595") }
    let(:rows) { [["Иванов И.И.", "11223344595", ""]] }

    it "skips duplicate" do
      expect { subject }.not_to change { Teacher.count }
      expect(result.skipped.size).to eq(1)
      expect(result.created).to be_empty
    end
  end

  context "with missing name" do
    let(:rows) { [["", "11223344595", ""]] }

    it "reports row in failed" do
      expect(result.failed.size).to eq(1)
      expect(result.failed.first.row).to eq(2)
      expect(result.failed.first.messages).to include("ФИО не указано")
    end
  end

  context "with missing snils" do
    let(:rows) { [["Иванов И.И.", "", ""]] }

    it "reports row in failed" do
      expect(result.failed.size).to eq(1)
      expect(result.failed.first.messages).to include("СНИЛС не указан")
    end
  end

  context "with blank row" do
    let(:rows) { [["", "", ""], ["Иванов И.И.", "11223344595", ""]] }

    it "ignores blank row and imports the rest" do
      expect(result.created.size).to eq(1)
      expect(result.failed).to be_empty
    end
  end

  context "with invalid snils format" do
    let(:rows) { [["Иванов И.И.", "not-a-snils", ""]] }

    it "reports validation failure" do
      expect(result.failed.size).to eq(1)
      expect(result.failed.first.messages.join).to match(/СНИЛС/i)
    end
  end
end
