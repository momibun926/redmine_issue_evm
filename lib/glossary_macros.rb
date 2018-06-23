module GlossaryMacros

  Redmine::WikiFormatting::Macros.register do

    desc "create macro which links to glossary term by id."
    macro :termno do |obj, args|
      begin
        raise 'no parameters' if args.count.zero?
        raise 'too many parameters' if args.count > 1
        term_id = args.first
        term = GlossaryTerm.find(term_id)
        link_to term.name, project_glossary_term_path(@project, term)
      rescue => err_msg
        raise <<-TEXT.html_safe
Parameter error: #{err_msg}<br>
Usage: {{termno(glossary_term_id)}}
TEXT
      end
    end

    desc "create macro which links to glossary term by name."
    macro :term do |obj, args|
      begin
        raise 'no parameters' if args.count.zero?
        raise 'too many parameters' if args.count > 1
        term = GlossaryTerm.find_by!(name: args.first)
        link_to term.name, project_glossary_term_path(@project, term)
      rescue => err_msg
        raise <<-TEXT.html_safe
Parameter error: #{err_msg}<br>
Usage: {{term(name)}}
TEXT
      end
    end

  end

end
