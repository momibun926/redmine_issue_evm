class CreateGlossaryStyles < ActiveRecord::Migration
  def self.up
    create_table :glossary_styles do |t|
      t.column :show_desc, :boolean, :default => false
      t.column :groupby, :integer, :default => 1
      t.column :project_scope, :integer, :default => 0
      t.column :sort_item_0, :string, :default => ''
      t.column :sort_item_1, :string, :default => ''
      t.column :sort_item_2, :string, :default => ''
      t.column :user_id, :integer, :default => 0
    end

    add_column :terms, :rubi, :string, :default => ''
    add_column :terms, :abbr_whole, :string, :default => ''

  end


  def self.down
    drop_table :glossary_styles
    remove_column :terms, :abbr_whole
    remove_column :terms, :rubi
  end
end
