# Project report
#
class CreateProjectEvmreports < ActiveRecord::Migration[4.2]
  # 1st create
  def change
    create_table :project_evmreports do |t|
      t.integer :project_id
      t.date :status_date
      t.text :report_text
      t.integer :baseline_id
      t.float :evm_bac
      t.float :evm_pv
      t.float :evm_ev
      t.float :evm_ac
      t.float :evm_sv
      t.float :evm_cv
      t.integer :create_user_id
      t.datetime :created_on
      t.integer :update_user_id
      t.datetime :updated_on
    end
  end
end
