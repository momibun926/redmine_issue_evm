class GlossaryTerm < ActiveRecord::Base
  belongs_to :category, class_name: 'GlossaryCategory', foreign_key: 'category_id'
  belongs_to :project

  scope :search_by_name, -> (keyword) {
    where 'name like ?', "#{sanitize_sql_like(keyword)}%"
  }

end
