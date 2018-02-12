module Mongo
  class Data < MongoRecord
    include Mongoid::Document
    include Mongoid::Copyable
    include Mongoid::Attributes::Dynamic

    embedded_in :policy, class_name: 'Mongo::Policy'

  end
end
