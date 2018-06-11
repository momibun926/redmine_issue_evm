class GlossaryTerm < ActiveRecord::Base
  belongs_to :category, class_name: 'GlossaryCategory', foreign_key: 'category_id'
  belongs_to :project

  # class method from Redmine::Acts::Attachable::ClassMethods
  acts_as_attachable view_permission: :view_glossary, edit_permission: :manage_glossary, delete_permission: :manage_glossary

  acts_as_event datetime: :updated_at,
                description: :description,
                author: nil,
                title: Proc.new {|o| "#{l(:glossary_title)} ##{o.id} - #{o.name}" },
                url: Proc.new {|o| { controller: 'glossary_terms',
                                     action: 'show',
                                     id: o.id,
                                     project_id: o.project }
  }

  acts_as_activity_provider scope: joins(:project),
                            type: 'glossary_terms',
                            permission: :view_glossary,
                            timestamp: :updated_at
  
  scope :search_by_name, -> (keyword) {
    where 'name like ?', "#{sanitize_sql_like(keyword)}%"
  }

  scope :search_by_rubi, -> (keyword) {
    where 'rubi like ?', "#{sanitize_sql_like(keyword)}%"
  }

end
