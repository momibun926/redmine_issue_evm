require File.expand_path("evm_functional_test_helper", __dir__)

# The links of the pages of the baselines have icons, in the style of Redmine 7 (an SVG of the
# sprite of Redmine in front of the label).
class EvmbaselinesControllerIconsTest < Redmine::ControllerTest
  tests EvmbaselinesController
  include EvmFunctionalTestSupport

  def setup
    sign_in_as_project_member
    plans = [[@issue1, Date.new(2026, 1, 5), Date.new(2026, 1, 9), 40.0]]
    @old = create_baseline("old baseline", Time.utc(2026, 1, 1), plans)
    @latest = create_baseline("latest baseline", Time.utc(2026, 1, 3), plans)
  end

  def test_index_links_have_icons
    get :index, params: { project_id: @project.id }

    assert_link_icon I18n.t(:label_nav_main), "projects"
    assert_link_icon I18n.t(:label_baseline_create), "add"
    assert_select "td.buttons a.icon", 6
    assert_select "td.buttons a.icon use[href$=?]", "#icon--zoom-in", 2
    assert_select "td.buttons a.icon use[href$=?]", "#icon--edit", 2
    assert_select "td.buttons a.icon use[href$=?]", "#icon--del", 2
  end

  def test_new_edit_and_show_have_the_back_link_with_an_icon
    get :new, params: { project_id: @project.id }
    assert_link_icon I18n.t(:button_back), "arrow-narrow-left"

    get :edit, params: { project_id: @project.id, id: @latest.id }
    assert_link_icon I18n.t(:button_back), "arrow-narrow-left"

    get :show, params: { project_id: @project.id, id: @latest.id }
    assert_link_icon I18n.t(:button_back), "arrow-narrow-left"
  end
end
