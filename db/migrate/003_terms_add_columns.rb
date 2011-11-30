class TermsAddColumns < ActiveRecord::Migration
  def self.up
    add_column :terms, :tech_en, :string, :default => ''
    add_column :terms, :name_cn, :string, :default => ''
    add_column :terms, :name_fr, :string, :default => ''
  end


  def self.down
    remove_column :terms, :tech_en
    remove_column :terms, :name_cn
    remove_column :terms, :name_fr
  end
end
