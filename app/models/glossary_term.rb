class GlossaryTerm < ActiveRecord::Base
  belongs_to :category, class_name: 'GlossaryCategory', foreign_key: 'category_id'
end
