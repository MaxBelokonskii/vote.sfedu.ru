module Admin::TeachersHelper
  KIND_LABELS = {
    "common" => "Общий",
    "physical_education" => "Физкультура",
    "foreign_language" => "Иностранный язык"
  }.freeze

  def teacher_kind_label(teacher)
    KIND_LABELS.fetch(teacher.kind.to_s, teacher.kind.to_s)
  end

  def teacher_kind_options
    KIND_LABELS.map { |value, label| [label, value] }
  end
end
