class CreateEvmbaselineSubProjects < ActiveRecord::Migration
  def change
    create_table :evmbaseline_sub_projects do |t|
      t.integer :evmbaseline_id
      t.integer :sub_project_id
    end
  end
end
