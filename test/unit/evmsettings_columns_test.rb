require File.expand_path("../test_helper", __dir__)

# db/migrate/010_remove_view_version_from_evmsettings.rb removes the column
# that the common setting page has no field for.
class EvmsettingsColumnsTest < ActiveSupport::TestCase
  def test_the_setting_has_no_view_version_column
    assert_not ActiveRecord::Base.connection.column_exists?(:evmsettings, :view_version)
    assert_not Evmsetting.new.respond_to?(:view_version)
  end
end
