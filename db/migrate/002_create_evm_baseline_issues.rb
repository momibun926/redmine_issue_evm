class CreateEvmBaselineIssues < ActiveRecord::Migration
  def change
    create_table :evm_baseline_issues do |t|
      t.integer :project_id
      t.date :strat_date
      t.date :due_date
      t.integer :estimate_hours
      t.boolean :leaf
    end
  end
end
