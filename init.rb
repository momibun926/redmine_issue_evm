require 'redmine'

Redmine::Plugin.register :redmine_issue_evm do
	
  name 'Redmine Issue Evm plugin'
  author 'Hajime Nakagama'
  description 'This is a plugin for Redmine. Earned value management using the ticket of redmine.'
  version '3.0'
  url 'https://github.com/momibun926/redmine_issue_evm'
  author_url 'https://github.com/momibun926'
  
  project_module :Issuevm do
    permission :view_evms, :evms => :index , :require => :member
    permission :manage_evms, { :evmbaselines => [:edit, :destroy, :new, :create, :update, :index] } 
  end

  menu :project_menu, :issuevm, { :controller => :evms, :action => :index}, :caption => 'IssueEVM', :param => :project_id

end
