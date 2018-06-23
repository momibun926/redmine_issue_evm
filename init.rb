#Rails.configuration.to_prepare do
#  Redmine::Activity.register :glossary_terms
#end

Redmine::Plugin.register :redmine_glossary do
  name 'Redmine Glossary plugin'
  author 'Toru Takahashi'
  description 'This is a plugin for Redmine to create a glossary that is a list of terms in a project.'
  version '1.0.1'
  url 'https://github.com/torutk/redmine_glossary'
  author_url 'http://www.torutk.com'


  project_module :glossary do
    permission :view_glossary, {
                 glossary_terms: [:index, :show],
                 glossary_categories: [:index, :show]
               }
    permission :manage_glossary, {
                 glossary_terms: [:new, :create, :edit, :update, :destroy],
                 glossary_categories: [:new, :create, :edit, :update, :destroy],
               },
               require: :member

  end

  menu :project_menu, :glossary,
       { controller: :glossary_terms, action: :index },
       caption: :glossary_title,
       param: :project_id

end


Redmine::Activity.register :glossary_terms

Redmine::WikiFormatting::Macros.register do
  desc "create macro which links to glossary term."
  macro :termno do |obj, args|
    puts "@@@@@@@@@@@@ Macros.register macro block: obj=#{obj.inspect} @@@@@@@@@@@@"
    term_id = args.first
    term = GlossaryTerm.find(term_id)
    link_to term.name, project_glossary_term_path(@project, term)
  end
  macro :term do |obj, args|
    term = GlossaryTerm.find_by(name: args.first)
    link_to 
  end
end
