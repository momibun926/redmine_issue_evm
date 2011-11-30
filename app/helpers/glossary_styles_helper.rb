module GlossaryStylesHelper

  def retrieve_glossary_style
    if (User.current.anonymous?)
      if (session[:glossary_style])
        @glossary_style = GlossaryStyle.new(session[:glossary_style])
      end
    else
      if !params[:glossary_style_id].blank?
        @glossary_style = GlossaryStyle.find(params[:glossary_style_id])
      else
        @glossary_style= GlossaryStyle.find(:first, :conditions => "user_id = #{User.current.id}")
      end
    end

    unless (@glossary_style)
      @glossary_style = GlossaryStyle.new(:groupby => GlossaryStyle::GroupByCategory)
      @glossary_style.user_id = User.current.id
    end

  end

  def search_index_table(ary, sepcnt, proj, search_index_type = nil)
    return ""	if (!ary.is_a?(Array) or sepcnt <= 0)
    str = '<table><tr>'
    cnt = 0
    for ch in ary
      str += '</tr><tr>'	if ((cnt != 0) and (cnt % sepcnt) == 0 )
      cnt += 1
      str += '<td>'
      if (ch and !ch.empty?)
        prms = {:controller => 'glossary', :action => 'index',  :id => proj,
                :search_index_ch => ch}
        prms[:search_index_type] = search_index_type	if (search_index_type)
        str += link_to(ch, prms)
      end
      str += '</td>'
    end
    str += '</tr></table>'
  end

  def search_params
    [:search_str, :search_category, :latest_days]
  end

  def search_params_all
    search_params + [:search_index_ch, :search_index_type]
  end

  def add_search_params(prms)
    search_params_all.each {|prm|
      prms[prm] = params[prm]	if (params[prm] and !params[prm].empty?)
    }
  end
  
  def glossary_searching?
    search_params.each {|prm|
      return true 	if (params[prm] and !params[prm].empty?)
    }
    return false
  end  


  def authorized_projects(projscope, curproj, authcnd)
    ary = []
    case projscope
    when GlossaryStyle::ProjectCurrent
      return [curproj]
    when GlossaryStyle::ProjectMine
      ary = User.current.memberships.collect(&:project).compact.uniq
    when GlossaryStyle::ProjectAll
      ary = Project.visible.find(:all)
    end
    ary.find_all {|proj|
      User.current.allowed_to?(authcnd, proj)
    }
  end


  def break_categories(cats)
    catstrs = []
    cats.each  {|cat|
      catstrs << cat.name
      if (cat.name.include?('/'))
        str = cat.name
        while (str =~ /^(.+)\/[^\/]+$/)
          str = $1
          catstrs << str
        end
      end
    }
    catstrs
  end
  
  def seach_category_options(projscope, curproj)
    options = [""]
    projs = authorized_projects(projscope, curproj, {:controller => :glossary, :action => :index})
    unless (projs.empty?)
      querystr = projs.collect {|proj| "project_id = #{proj.id}"}.join(" OR ")
      options += break_categories(TermCategory.find(:all, :conditions => querystr)).sort.uniq
    end
    options << "(#{l(:label_not_categorized)})"
  end

  
end
