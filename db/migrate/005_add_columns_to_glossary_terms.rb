class AddColumnsToGlossaryTerms < ActiveRecord::Migration[5.1]
  def change
    add_column :glossary_terms, :name_en, :string, default: ''
    add_column :glossary_terms, :rubi, :string, default: ''
    add_column :glossary_terms, :abbr_whole, :string, default: ''
    add_column :glossary_terms, :datatype, :string, default: ''
    add_column :glossary_terms, :codename, :string, default: ''
  end
end
