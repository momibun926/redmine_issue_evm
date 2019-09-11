# Stored issue of baseline
#
class CreateEvmbaselineIssues < ActiveRecord::Migration
  # 1st create
  def change
    create_table :evmbaseline_issues do |t|
      t.integer :evmbaseline_id
      t.integer :issue_id
      t.date :start_date
      t.date :due_date
      t.float :estimated_hours
      t.boolean :leaf
    end
  end
end
