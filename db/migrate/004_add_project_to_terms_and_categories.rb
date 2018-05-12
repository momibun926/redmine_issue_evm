class AddProjectToTermsAndCategories < ActiveRecord::Migration[5.1]
  def change
    add_reference :glossary_terms, :project, foreign_key: true
    add_reference :glossary_categories, :project, foreign_key: true
  end
end
