require "redmine"
require "holidays/core_extensions/date"

# Extention for ate class
class Date
  include Holidays::CoreExtensions::Date
end

# View listener for activity page
class RedmineIssueEvmHookListener < Redmine::Hook::ViewListener
  render_on :view_layouts_base_html_head, inline: "<%= stylesheet_link_tag 'issue_evm', :plugin => :redmine_issue_evm %>"
end

# for search and activity page
if Rails.version > "6.0" && Rails.autoloaders.zeitwerk_enabled?
  Redmine::Activity.register "evmbaseline"
  Redmine::Activity.register "project_evmreport"
  Redmine::Search.available_search_types << "evmbaselines"
  Redmine::Search.available_search_types << "project_evmreports"
else
  Rails.configuration.to_prepare do
    Redmine::Activity.register "evmbaseline"
    Redmine::Activity.register "project_evmreport"
    Redmine::Search.available_search_types << "evmbaselines"
    Redmine::Search.available_search_types << "project_evmreports"
  end
end

# module define
Redmine::Plugin.register :redmine_issue_evm do
  name "Redmine Issue Evm plugin"
  author "Hajime Nakagama"
  description "Earned value management calculation plugin."
  version "6.0.1"
  url "https://github.com/momibun926/redmine_issue_evm"
  author_url "https://github.com/momibun926"
  project_module :Issuevm do
    permission :view_evms, evms: :index, require: :member
    permission :manage_evmbaselines,
               evmbaselines: %i[edit destroy new create update index show history]
    permission :view_evmbaselines,
               evmbaselines: %i[index history show]
    permission :manage_evmsettings,
               evmsettings: %i[ndex edit]
    permission :view_project_evmreports,
               evmreports: %i[index show new create edit destroy]
  end

  # menu
  menu :project_menu, :issuevm, { controller: :evms, action: :index },
       caption: :tab_display_name, param: :project_id

  # load holidays
  Holidays.load_all
end
