class Teacher < ApplicationRecord
  has_one :user, as: :kind, dependent: :destroy
  has_many :students_teachers_relations, dependent: :destroy
  has_many :answers, dependent: :destroy
  has_many :participations, dependent: :destroy
  has_many :stages, -> { distinct }, through: :participations
  has_many :teachers_rosters, dependent: :destroy

  enum kind: [:common, :physical_education, :foreign_language]
  enum origin: {imported: "imported", manual: "manual"}, _prefix: :origin

  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  before_save :encrypt_snils_if_changed

  validates :name, presence: true
  validates :snils, format: {with: /\A\d{11}\z/, allow_blank: true, message: "должен содержать 11 цифр"}
  validates :snils, presence: true, if: :origin_manual?
  validates :encrypted_snils, uniqueness: {allow_blank: true, message: "преподаватель с таким СНИЛС уже существует"}
  validate :snils_checksum_valid, if: -> { origin_manual? && snils.present? }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name external_id kind origin created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  def soft_delete!
    update_column(:deleted_at, Time.current)
  end

  def deleted?
    deleted_at.present?
  end

  def editable_by_admin?
    origin_manual?
  end

  def stage_relations(stage)
    students_teachers_relations.where(semester: stage.semesters)
  end

  def relations_by_semesters
    students_by_semesters = students_teachers_relations.group(:semester_id).order(:semester_id).count
    semesters = Semester.all.index_by(&:id)
    current_stage = Stage.current

    students_by_semesters.filter_map do |k, v|
      semester = semesters[k]
      next if semester.nil?

      {
        semester: semester.full_title.capitalize,
        is_current: current_stage&.semester_ids&.include?(k) || false,
        count: v
      }
    end
  end

  def relations_count
    students_teachers_relations.pluck(:student_id).count
  end

  def normalize_snils!
    update(snils: Snils.normalize(snils)) unless snils.nil?
  end

  def encrypt_snils!
    update(encrypted_snils: Snils.encrypt(snils))
  end

  private

  def encrypt_snils_if_changed
    return unless snils.present? && snils_changed?
    self.encrypted_snils = Snils.encrypt(snils)
  end

  def snils_checksum_valid
    check = SnilsCheck.new(snils)
    errors.add(:snils, "неверная контрольная сумма СНИЛС") unless check.valid?
  end
end
