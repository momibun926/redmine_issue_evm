class CreateGlossaryTerms < ActiveRecord::Migration[5.1]
  def change
    create_table :glossary_terms do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps null: false
    end
  end
end
