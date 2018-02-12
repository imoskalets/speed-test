module Mongo
  class Policy < MongoRecord
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mongoid::Copyable
    include GlobalID::Identification

    index({ user_id: 1 }, { name: 'user_index' })

    field :user_id, type: Integer

    embeds_one :data, class_name: 'Mongo::Data', cascade_callbacks: true

  end
end
