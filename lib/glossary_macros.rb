module GlossaryMacros

  Redmine::WikiFormatting::Macros.register do

    desc "create macro which links to glossary term by id."
    macro :termno do |obj, args|
      term_id = args.first
      term = GlossaryTerm.find(term_id)
      link_to term.name, project_glossary_term_path(@project, term)
    end

    desc "create macro which links to glossary term by name."
    macro :term do |obj, args|
      term = GlossaryTerm.find_by(name: args.first)
      link_to term.name, project_glossary_term_path(@project, term)
    end

  end

end
