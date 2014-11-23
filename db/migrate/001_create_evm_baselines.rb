class CreateEvmBaselines < ActiveRecord::Migration
  def change
    create_table :evm_baselines do |t|
      t.integer :project_id
      t.string :state
      t.string :subject
      t.text :description
    end
  end
end
