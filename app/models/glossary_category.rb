class GlossaryCategory < ActiveRecord::Base
  has_many :terms, class_name: 'GlossaryTerm', foreign_key: 'category_id'
end
