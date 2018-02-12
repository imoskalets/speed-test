class Policy < ApplicationRecord

  serialize :data, JSON

  belongs_to :user, optional: true

end
