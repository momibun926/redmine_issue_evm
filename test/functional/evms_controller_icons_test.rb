require File.expand_path("evm_functional_test_helper", __dir__)

# The links at the top right of the EVM pages carry an icon, drawn the way Redmine 7 does
# it: an SVG that points at a symbol of the sprite of Redmine, or of this plugin (the icons
# which Redmine does not have: assets/images/icons.svg).
class EvmsControllerIconsTest < Redmine::ControllerTest
  # label of the link => icon (the sprite of this plugin when the name begins with "evm-")
  ICONS = {
    label_nav_main: "projects",
    label_nav_version: "package",
    label_nav_assignee: "user",
    label_nav_parent_issue: "evm-parent-issue",
    label_nav_tracker: "evm-tracker",
    label_nav_exclude: "circle-minus",
    label_nav_baseline_setting: "history",
    label_nav_evm_setting: "settings"
  }.freeze

  tests EvmsController
  include EvmFunctionalTestSupport

  def setup
    sign_in_as_project_member
    create_evm_setting
  end

  def test_every_link_has_its_icon_in_front_of_the_label
    get :index, params: { project_id: @project.id, basis_date: "2026-01-08" }

    ICONS.each do |label, icon|
      assert_select "div.contextual a.icon" do |links|
        link = links.find { |a| a.text.strip == I18n.t(label) }
        assert link, "no link #{label}"
        assert_equal "svg", link.children.first.name, "the icon comes before the label of #{label}"
        assert_match(/#icon--#{icon}\z/, link.at("use")["href"], label.to_s)
      end
    end
  end

  def test_the_report_links_have_their_icons
    get :index, params: { project_id: @project.id, basis_date: "2026-01-08" }

    assert_select "div.contextual a[href*=?] use[href$=?]", "evmreports/new", "#icon--document"
    assert_select "div.contextual a[href*=?] use[href$=?]", "evmreports", "#icon--list"
  end

  def test_every_icon_is_in_the_sprite_it_points_at
    get :index, params: { project_id: @project.id, basis_date: "2026-01-08" }

    hrefs = css_select("div.contextual a use").pluck("href")
    assert_equal 10, hrefs.size
    hrefs.each do |href|
      sprite, name = href.split("#icon--")
      assert_includes symbols_of(sprite), name, href
    end
  end

  private

  # The names of the symbols of the sprite of this plugin or of Redmine
  def symbols_of(sprite_path)
    file = if sprite_path.include?("plugin_assets/redmine_issue_evm/")
             File.expand_path("../../assets/images/icons.svg", __dir__)
           else
             Rails.root.join("app/assets/images/icons.svg")
           end
    File.read(file).scan(/<symbol[^>]*\sid="icon--([^"]+)"/).flatten
  end
end
