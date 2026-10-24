require File.expand_path("evm_functional_test_helper", __dir__)

# The events of the baselines and of the reports on the activity page have icons drawn the
# way Redmine 7 does it: an SVG that points at the symbol named like the type of the event in
# the sprite of this plugin (assets/images/icons.svg).
class ActivitiesControllerEvmIconsTest < Redmine::ControllerTest
  EVENT_TYPES = %w[evmbaseline-new evmbaseline-edit evmreports-new evmreports-edit].freeze

  tests ActivitiesController
  include EvmFunctionalTestSupport

  def setup
    sign_in_as_project_member
    create_evm_setting
    @baseline = create_baseline("baseline", 2.days.ago, [[@issue1, Date.new(2026, 1, 5), Date.new(2026, 1, 9), 40.0]])
    @edited = create_baseline("edited baseline", 3.days.ago, [])
    @edited.update!(updated_on: 1.day.ago)
    create_report("report", 2.days.ago, 2.days.ago)
    create_report("edited report", 3.days.ago, 1.day.ago)
  end

  def test_the_events_point_at_the_symbols_of_the_sprite_of_the_plugin
    get :index, params: { id: @project.id, from: Date.current.to_s, show_evmbaselines: 1, show_project_evmreports: 1 }

    assert_response :success
    events = css_select("#activity dt").select { |dt| EVENT_TYPES.include?(dt["class"].split.first) }
    assert_equal EVENT_TYPES.sort, events.map { |dt| dt["class"].split.first }.sort
    events.each do |dt|
      type = dt["class"].split.first
      assert_match(%r{plugin_assets/redmine_issue_evm/icons.*\.svg#icon--#{type}\z}, dt.at("use")["href"], type)
    end
  end

  def test_the_sprite_of_the_plugin_has_the_symbol_of_every_type_of_event
    symbols = File.read(File.expand_path("../../assets/images/icons.svg", __dir__)).scan(/\sid="icon--([^"]+)"/).flatten

    assert_empty EVENT_TYPES - symbols
  end

  private

  def create_report(text, created_on, updated_on)
    ProjectEvmreport.create!(project_id: @project.id, status_date: created_on.to_date, report_text: text,
                             baseline_id: @baseline.id, evm_bac: 1.0, author_id: 3, create_user_id: 3,
                             update_user_id: 3, created_on: created_on, updated_on: updated_on)
  end
end
