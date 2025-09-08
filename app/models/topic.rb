class Topic < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged
  has_many :articles, dependent: :nullify
  validates :name, presence: true, uniqueness: true
  def should_generate_new_friendly_id?
    name_changed? || slug.blank?
  end
end
