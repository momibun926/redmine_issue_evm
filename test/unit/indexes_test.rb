require File.expand_path("../test_helper", __dir__)

# The indexes added by db/migrate/009_add_indexes.rb.
class IndexesTest < ActiveSupport::TestCase
  def test_the_lookup_columns_have_indexes
    connection = ActiveRecord::Base.connection

    assert connection.index_exists?(:evmbaseline_issues, :evmbaseline_id)
    assert connection.index_exists?(:evmbaselines, :project_id)
    assert connection.index_exists?(:evmsettings, :project_id)
    assert connection.index_exists?(:project_evmreports, %i[project_id status_date])
  end
end
