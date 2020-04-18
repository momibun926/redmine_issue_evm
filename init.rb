require "redmine"
require "holidays/core_extensions/date"

# Extention for ate class
class Date
  include Holidays::CoreExtensions::Date
end

# for search and activity page
Rails.configuration.to_prepare do
  Redmine::Activity.register "evmbaseline"
  Redmine::Search.available_search_types << "evmbaselines"
end

# module define
Redmine::Plugin.register :redmine_issue_evm do
  name "Redmine Issue Evm plugin"
  author "Hajime Nakagama"
  description "Earned value management calculation plugin."
  version "5.3.4"
  url "https://github.com/momibun926/redmine_issue_evm"
  author_url "https://github.com/momibun926"
  project_module :Issuevm do
    permission :view_evms, evms: :index, require: :member
    permission :manage_evmbaselines,
               evmbaselines: [:edit, :destroy, :new, :create, :update, :index, :show, :history]
    permission :view_evmbaselines,
               evmbaselines: [:index, :history, :show]
    permission :manage_evmsettings,
               evmsettings: [:index, :edit]
  end

  # menu
  menu :project_menu, :issuevm, { controller: :evms, action: :index },
       caption: :tab_display_name, param: :project_id

  # View listener for activity page
  class RedmineIssueEvmHookListener < Redmine::Hook::ViewListener
    render_on :view_layouts_base_html_head, inline: "<%= stylesheet_link_tag 'issue_evm', :plugin => :redmine_issue_evm %>"
  end

  # load holidays
  Holidays.load_all
end
