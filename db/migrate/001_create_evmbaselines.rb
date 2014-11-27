class CreateEvmbaselines < ActiveRecord::Migration
  def change
    create_table :evmbaselines do |t|
      t.integer :id
      t.integer :project_id
      t.string :subject
      t.text :description
      t.string :state
      t.datetime :created_on
    end
  end
end
