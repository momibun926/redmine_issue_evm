class AddCategoryToGlossaryTerms < ActiveRecord::Migration[5.1]
  def change
    add_reference :glossary_terms, :category, foreign_key: true
  end
end
