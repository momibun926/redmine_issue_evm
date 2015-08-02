
class GlossaryController < ApplicationController
  menu_item :glossary
  unloadable

  layout 'base'  
  before_filter :find_project, :authorize
  before_filter :find_term, :only => [:show, :edit, :destroy]
  before_filter :retrieve_glossary_style, :only => [:index, :show, :show_all, :import_csv_exec]
  
  helper :attachments
  include AttachmentsHelper
  helper :sort
  include SortHelper
  helper :glossary
  include GlossaryHelper
  helper :glossary_port
  include GlossaryPortHelper
  helper :glossary_styles
  include GlossaryStylesHelper


  def index
    
    @is_index = true
    set_show_params
    @terms = find_terms(@glossary_style.project_scope)
    unless @terms.empty?
      sortparams = @glossary_style.sort_params
      sort_terms(@terms, sortparams)	unless sortparams.empty?
      off_params = @show_params.clone
      off_params.delete("category")
      off_params.delete("project")
      if (!@glossary_style.grouping?)
        check_nouse_params(@terms, off_params)
      else
        @terms = grouping(@glossary_style.groupby, @terms, off_params)
      end
      @show_params.delete_if {|prm| off_params.member?(prm) }
    end


    respond_to do |format|
      format.html { render :template => 'glossary/index.html.erb', :layout => !request.xhr? }
      format.csv  {
        ary = @terms        
        ary = GroupingTerms.flatten(@terms)	if (@glossary_style.grouping?)
        send_data(glossary_to_csv(ary), :type => 'text',
                  :filename => "glossary-export.csv")
      }
    end
  end


  def index_clear
    params[:search_index_ch] = nil
    redirect_to :controller => 'glossary', :action => 'index', :project_id => @project
  end
  

  def show
    set_show_params
    @term_categories = TermCategory.where(:project_id => @project.id).order(:position)
    respond_to do |format|
      format.html { render :template => 'glossary/show.html.erb', :layout => !request.xhr? }
    end
  end

  def new
    @term_categories = TermCategory.where(:project_id => @project.id).order(:position)
    @term = Term.new(params[:term])
    @term.name = CGI::unescapeHTML(params[:new_term_name])	if params[:new_term_name]
    @term.project_id = @project.id

    unless (request.get? || request.xhr?)
      @term.author_id = User.current.id
      @term.updater_id = User.current.id
      if @term.save
        attach_files(@term, params[:attachments])
        flash[:notice] = l(:notice_successful_create)
        if (params[:continue])
          redirect_to :controller => 'glossary', :action => 'new', :project_id => @project
        else
          redirect_to :controller => 'glossary', :action => 'show', :project_id => @project,
                  :id => @term
        end
      end		
    end
  end

  def preview
    @text = params[:term][:description]
    render :partial => 'common/preview'
  end

  def edit
    @term_categories = TermCategory.where(:project_id => @project.id).order(:position)
    
    if request.post? || request.put? || request.patch?
      @term.attributes = params[:term]
      @term.updater_id = User.current.id
      if @term.save
        attach_files(@term, params[:attachments])
        flash[:notice] = l(:notice_successful_update)
        redirect_to(:controller => 'glossary', :action => 'show', 
          :project_id => @project, :id => @term.id)
        return
      end
    end
  rescue ActiveRecord::StaleObjectError
    # Optimistic locking exception
    flash.now[:error] = l(:notice_locking_conflict)
  end

  def destroy
    @term.destroy
    redirect_to :action => 'index', :project_id => @project
  end

  def add_term_category
    @category = TermCategory.new(params[:category])
    @category.project_id = @project.id
    if request.post? and @category.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_create)
          redirect_to :controller => 'term_categories', :action => 'index', :project_id => @project
        end
        format.js do
          term_categories = TermCategory.where(:project_id => @project.id)
          render(:update) {|page| page.replace "term_category_id",
            content_tag('select', '<option></option>' + options_from_collection_for_select(term_categories, 'id', 'name', @category.id), :id => 'term_category_id', :name => 'term[category_id]')
          }
        end
      end
    end
  end


  def move_all
    projs = Project.visible.all
    @allowed_projs = projs.find_all {|proj|
      User.current.allowed_to?({:controller =>'glossary', :action => 'index'}, proj) and
        User.current.allowed_to?({:controller =>'glossary', :action => 'move_all'}, proj) and
        proj != @project
    }
    if request.post?
      newproj = Project.find(params[:new_project_id])
      cats = TermCategory.where(:project_id => newproj.id).order(:position)
      posbase = (cats.blank?) ? 0 : cats.last.position - 1;
      cats = TermCategory.where(:project_id => @project.id)
      cats.each {|cat|
        cat.project_id = newproj.id
        cat.position += cat.position + posbase
        cat.save
      }
      Term.where(project_id: @project.id).update_all(project_id: newproj.id)
      flash[:notice] = l(:notice_successful_update)
      redirect_to({:action => 'index', :project_id => newproj})
    end
  end
  

  def import_csv
  end

  def import_csv_exec
    @import_info = CsvGlossaryImportInfo.new(params)
    glossary_from_csv(@import_info, @project.id)
    if (@import_info.success?)
      flash[:notice] = l(:notice_successful_create)
    else
      flash.now[:error] = l(:error_import_failed) + " " + @import_info.err_string
    end
  end

  
  private

  def show_param?(prmname)
    case prmname
    when 'project'
      return false	unless @glossary_style.project_scope != GlossaryStyle::ProjectCurrent
      return true	unless @is_index
      @glossary_style.groupby != GlossaryStyle::GroupByProject
    when 'category'
      return true	unless @is_index
      @glossary_style.groupby != GlossaryStyle::GroupByCategory
    when 'rubi'
      (param_visible?(prmname) and !@is_index)
    when 'abbr_whole'
      (param_visible?(prmname) and !@is_index)
    else
      param_visible?(prmname)
    end
  end

  def set_show_params
    @show_params = default_show_params.find_all {|prmname|
      show_param?(prmname)
    }
  end

  def check_nouse_params(terms, off_params)
    terms.each {|term|
      return 	if off_params.empty?
      off_params.delete_if {|prm| !term[prm].empty? }
    }
  end

  def grouping(type, terms, off_params)
    grouptbl = {}    
    terms.each {|term|
      off_params.delete_if {|prm| !term[prm].empty? }
      tgt = (type == GlossaryStyle::GroupByProject) ? term.project : term.category
      gterms = grouptbl[tgt];
      unless (gterms)
        gterms = GroupingTerms.new(type, tgt)
        grouptbl[tgt] = gterms
      end
      gterms.ary << term
    }
    grouptbl.values.sort
  end


  #### sort
  
  def sort_terms(terms, prms)
    terms.to_a.sort! {|a, b|
      re = nil
      prms.each {|prm|
        re = Term.compare_by_param(prm, a, b)
        break	if (re != 0)
      }
      (re == 0) ? a.id <=> b.id : re
    }
  end


  #### find

  def join_queries(ary, ex = 'OR')
    joinstr = " #{ex} "
    ((ary.size == 1) ? ary[0] : "( #{ary.join(joinstr)} )")
  end

  def query_project_scope(projscope, queries)
    ary = authorized_projects(projscope, @project,
                              {:controller => :glossary, :action => :index})
    return false	if ary.empty?
    queries << join_queries(ary.collect{|proj| "project_id = #{proj.id}" })
    true
  end

  def query_category(catname, queries)
    return	if (!catname or catname.empty? )
    if (catname == "(#{l(:label_not_categorized)})")
      queries << "( category_id IS NULL )"
    else
      cats = TermCategory.where(["name LIKE :catname",
                                                     {:catname => catname + "%"}])
      ary = []
      ptn = /^#{Regexp.escape(catname)}\//
      cats.each {|encat|
        if (encat.name == catname or encat.name =~ ptn)
          ary << "category_id = #{encat.id}"
        end
      }
      queries << join_queries(ary)	unless (ary.empty?)
    end
  end


  def query_search_str(str, queries, symbols)
    return	unless (str and !str.empty?)
    strs = tokenize_by_space(str)
    cnt = 0
    strs.each {|ss|
      symbols["search_str_#{cnt}".to_sym] = "%#{ss}%"
      cnt += 1
    } 
    ary = []
    default_searched_params.each {|prm|
      subary = []
      cnt = 0
      strs.each {|ss|
        subary << "( #{prm} LIKE :search_str_#{cnt} )"
        cnt += 1
      } 
      ary << join_queries(subary, 'AND')
    }
    queries << join_queries(ary)	if (0 < ary.size)
  end


  def get_search_index_charset(ch, type)
    charset = [ch]
    return charset	if type
    idx = l(:index_ary).index(ch)
    subary = l(:index_subary)
    if (subary.is_a?(Array) and subary[idx] and !subary[idx].empty?)
      if (subary[idx].is_a?(Array))
        subary[idx].each {|subch|
          charset << subch
        }
      else
        charset << subary[idx]
      end
    end
    charset
  end
    

  def query_search_index(ch, type, queries, symbols)
    return	unless (ch and !ch.empty?)
    charset = get_search_index_charset(ch, type)
    searchprms = [:name, :abbr_whole, :rubi]
    searchprms << :name_en	if (type)
    cnt = 0
    charset.each {|tch|
      symbols["search_ch_#{cnt}".to_sym] = tch + '%'
      cnt += 1
    }
    ary = []
    searchprms.each {|prm|
      subary = []
      cnt = 0
      charset.each {|tch|
        subary << "( #{prm} LIKE :search_ch_#{cnt} )"
        cnt += 1
      } 
      ary << join_queries(subary)
    }
    @query_string = join_queries(ary)
    queries << join_queries(ary)	if (0 < ary.size)    
  end
  
  
  def find_terms(project_scope)
    queries = []
    symbols = {}
    return []	unless query_project_scope(project_scope, queries)
    query_category(params[:search_category], queries)
    query_search_str(params[:search_str], queries, symbols)
    query_search_index(params[:search_index_ch], params[:search_index_type],
                       queries, symbols)
    terms = nil
    if (queries.empty?)
      terms = Term.all
    else
      query_str = join_queries(queries, "AND")
      terms = Term.where(query_str, symbols)
    end
    if (terms and params[:latest_days] and !params[:latest_days].empty?)
      limitsec = Time.now.to_i - params[:latest_days].to_i * 60 * 60 * 24
      limittm = Time.at(limitsec)
      terms.delete_if {|prm|
        (prm.datetime < limittm)
      }
    else
      terms
    end
  end

  
  def find_project   
    project_id = params[:project_id] || (params[:issue] && params[:issue][:project_id])
    @project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def find_term
    @term = Term.find_by(project_id: @project.id, id: params[:id])
    render_404 unless @term
  rescue
    render_404
  end

  def attach_files(val, prm)
    Attachment.attach_files(val, prm)
  end

end
