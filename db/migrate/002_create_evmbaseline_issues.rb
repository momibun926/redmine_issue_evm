class CreateEvmbaselineIssues < ActiveRecord::Migration
  def change
    create_table :evmbaseline_issues do |t|
      t.integer :id
      t.integer :evmbaseline_id
      t.integer :issue_id
      t.date :start_date
      t.date :due_date
      t.integer :estimate_hours
      t.boolean :leaf
    end
  end
end
