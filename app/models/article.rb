class Article < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: [:slugged, :history]

  def should_generate_new_friendly_id?
    title_changed? || slug.blank?
  end
end
