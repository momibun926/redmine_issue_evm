# Remove evmsettings.view_version. The common setting page has no field for
# it, and nothing reads it.
#
class RemoveViewVersionFromEvmsettings < ActiveRecord::Migration[8.1]
  def up
    remove_column :evmsettings, :view_version if column_exists?(:evmsettings, :view_version)
  end

  def down
    add_column :evmsettings, :view_version, :boolean unless column_exists?(:evmsettings, :view_version)
  end
end
