module Admin::UsersHelper
  ROLE_LABELS = {
    "regular" => "Обычный",
    "moderator" => "Модератор",
    "admin" => "Администратор"
  }.freeze

  def translate_role(role)
    ROLE_LABELS.fetch(role.to_s, role.to_s)
  end
end
