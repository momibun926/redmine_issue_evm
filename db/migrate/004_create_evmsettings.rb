# View setting
#
class CreateEvmsettings < ActiveRecord::Migration[4.2]
  # 1st create
  def change
    create_table :evmsettings do |t|
      t.integer :project_id
      t.boolean :view_forecast
      t.boolean :view_version
      t.boolean :view_performance
      t.boolean :view_issuelist
      t.string :etc_method
      t.float :basis_hours
      t.float :threshold_spi
      t.float :threshold_cpi
      t.float :threshold_cr
      t.string :region
      t.integer :user_id
      t.datetime :updated_on
      t.datetime :created_on
    end
  end
end
