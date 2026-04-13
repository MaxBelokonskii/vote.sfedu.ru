class Stage < ApplicationRecord
  has_and_belongs_to_many :semesters
  has_and_belongs_to_many :questions
  has_many :participations
  has_many :teachers_rosters, dependent: :destroy

  after_save :recalculate_scale_ladder!

  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validates :lower_participants_limit, numericality: {greater_than_or_equal_to: 0, only_integer: true}
  validate :ends_at_after_starts_at
  validate :must_have_at_least_one_semester
  validate :must_have_at_least_one_question
  validate :scale_max_greater_than_scale_min

  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }
  scope :upcoming, -> { active.where("stages.starts_at > ?", Time.current) }
  scope :past, -> { active.where("stages.ends_at < ?", Time.current) }
  scope :running, -> {
    current_time = Time.current
    active.where("stages.starts_at <= ?", current_time).where("stages.ends_at >= ?", current_time)
  }

  def self.current
    running.first
  end

  def upcoming?
    Time.current < starts_at
  end

  def current?
    current_time = Time.current
    current_time.between?(starts_at, ends_at)
  end

  def past?
    ends_at < Time.current
  end

  def deleted?
    deleted_at.present?
  end

  def soft_delete!
    update_column(:deleted_at, Time.current)
  end

  def calculation_rule_klass
    CalculationRules::V2019Spring
  end

  def converted_scale_ladder
    return unless with_scale?

    recalculate_scale_ladder! if scale_ladder.blank?
    calculation_rule_klass.converted_scale_ladder(stage: self)
  end

  def recalculate_scale_ladder!
    return unless with_scale?

    ladder = calculation_rule_klass.recalculate_scale_ladder!(stage: self)
    update_column(:scale_ladder, ladder)
  end

  private

  def ends_at_after_starts_at
    return if starts_at.blank? || ends_at.blank?
    errors.add(:ends_at, "должна быть позже даты начала") if ends_at <= starts_at
  end

  def must_have_at_least_one_semester
    errors.add(:semesters, "должен быть указан хотя бы один семестр") if semesters.empty?
  end

  def must_have_at_least_one_question
    errors.add(:questions, "должен быть указан хотя бы один вопрос") if questions.empty?
  end

  def scale_max_greater_than_scale_min
    return unless with_scale?
    return if scale_min.blank? || scale_max.blank?
    errors.add(:scale_max, "должен быть больше минимального значения шкалы") if scale_max <= scale_min
  end
end
