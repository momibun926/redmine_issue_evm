class CreateEvmbaselines < ActiveRecord::Migration
  def change
    create_table :evmbaselines do |t|
      t.integer :project_id
      t.string :subject
      t.text :description
      t.string :state
      t.integer :author_id
      t.datetime :created_on
      t.integer :update_id
      t.datetime :updated_on
    end
  end
end
