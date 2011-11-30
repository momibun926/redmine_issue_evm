class CreateTerms < ActiveRecord::Migration
  def self.up
    # CreateTermCategories
    create_table :term_categories, :force => true do |t|
      t.column :project_id, :integer, :default => 0, :null => false
      t.column :name, :string, :default => '', :null => false
      t.column :position, :integer, :default => 1
    end

    add_index "term_categories", ["project_id"], :name => "categories_project_id"

    create_table :terms, :force => true do |t|
      t.column :project_id, :integer, :default => 0, :null => false
      t.column :category_id, :integer
      t.column :author_id, :integer, :default => 0, :null => false
      t.column :updater_id, :integer
      t.column :name, :string, :default => '', :null => false
      t.column :name_en, :string, :default => ''
      t.column :datatype, :string, :default => ''
      t.column :codename, :string, :default => ''
      t.column :description, :text
      t.column :created_on, :timestamp
      t.column :updated_on, :timestamp
    end

    add_index "terms", ["project_id"], :name => "terms_project_id"
    
  end
  
  def self.down
    drop_table :term_categories
    drop_table :terms
  end
end
