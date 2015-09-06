require 'redmine'
require 'cgi'
require 'glossary_asset_tag_helper_patch'
require 'term_link_helper'
require 'csv'
FCSV = CSV

ActionView::Base.class_eval do
  include ActionView::Helpers::TermLinkHelper
end


Redmine::Plugin.register :redmine_glossary do
  name 'Redmine Glossary Plugin'
  author 'M. Yoshida'
  description "This is a Redmine plugin to create a glossary which is is a list of terms in a project"
  version '0.9.2'
  requires_redmine :version_or_higher => '3.0.0'
  author_url 'http://yohshiy.blog.fc2.com/'
  url 'http://www.r-labs.org/projects/rp-glossary/wiki/GlossaryEn'

  settings :default => {
    'hide_item_term_en' => false,
    'hide_item_codename' => false,
    'hide_item_datatype' => false,
    'hide_item_rubi' => false,
    'hide_item_abbr_whole' => false,
  }, :partial => 'settings/glossary_settings'


  project_module :glossary do
    permission(:view_terms, {:glossary => [:index, :index_clear, :show, :show_all]})
    permission(:manage_terms, {:glossary => [:new, :edit, :destroy, :preview,
                                             :import_csv, :import_csv_exec, :move_all]},
               :require => :member)
    permission(:manage_term_categories,
               {:glossary => [:add_term_category, :move_all],
                :term_categories => [:index, :change_order, :edit, :destroy]},
               :require => :member)
  end

  menu(:project_menu, :glossary,
       { :controller => 'glossary', :action => 'index' },
       :caption => :glossary_title, :param => :project_id)

end



Redmine::WikiFormatting::Macros.register do
  desc "Glossary term link by ID"
  macro :termno do |obj, args|
    raise I18n.t(:error_termno_macro_arg)	if (args.size != 1)
    tid = args[0].strip
    term = Term.find_by_id(tid.to_i)
    raise sprintf(I18n.t(:error_term_not_found_id), tid) 	unless term
    term_link(term)
  end
end


Redmine::WikiFormatting::Macros.register do
  desc "Glossary term link"
  macro :term do |obj, args|
    sargs = args.map {|arg| CGI::unescapeHTML(arg.strip) }
    term = nil
    case sargs.size
    when 1
      proj = Project.find_by_identifier(params[:project_id])	unless proj
      term = Term.find_for_macro(sargs[0], proj, true)
    when 2
      proj = Project.find_by_identifier(sargs[1])
      raise sprintf(I18n.t(:error_project_not_found), sargs[1])	unless proj
      term = Term.find_for_macro(sargs[0], proj)
    else
      raise I18n.t(:error_term_macro_arg)
    end
    (term) ? term_link(term) : term_link_new(sargs[0], proj)
  end
end
