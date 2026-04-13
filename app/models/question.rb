class Question < ApplicationRecord
  has_and_belongs_to_many :stages
  has_many :answers

  validates :text, presence: true
  validates :max_rating, numericality: {only_integer: true, greater_than: 0}

  def used_in_stages?
    stages.any?
  end
end
