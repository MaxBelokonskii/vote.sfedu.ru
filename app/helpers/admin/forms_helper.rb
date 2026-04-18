module Admin::FormsHelper
  INPUT_BASE = "rounded-lg border px-3 py-2 text-sm focus_ring-2 focus_ring-primary focus_border-primary".freeze

  def admin_input_classes(record, attr, width: "w-full", extra: "")
    border = admin_field_error?(record, attr) ? "border-red-400 bg-red-50" : "border-gray-300"
    [width, INPUT_BASE, border, extra].reject(&:blank?).join(" ")
  end

  def admin_field_error?(record, attr)
    record.errors[attr].any?
  end
end
