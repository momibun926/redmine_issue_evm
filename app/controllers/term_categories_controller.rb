class TermCategoriesController < ApplicationController
  unloadable
  
  layout 'base'
  menu_item :glossary, :only => [:index, :edit, :destroy]
  
  before_filter :find_project, :authorize
  before_filter :retrieve_glossary_style, :only => [:index]

  helper :glossary
  include GlossaryHelper
  helper :glossary_styles
  include GlossaryStylesHelper


  def index
    @categories = TermCategory.where(project_id: @project.id).order(:position)
  end
  
  def edit
    @category = TermCategory.find_by(project_id: @project.id,  id: params[:id])
    if request.put? and @category.update_attributes(params[:category])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :controller => 'term_categories', :action => 'index', :project_id => @project
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def change_order
    if request.post? 
      category = TermCategory.find_by(project_id: @project.id, id: params[:id])
      case params[:position]
      when 'highest'; category.move_to_top
      when 'higher'; category.move_higher
      when 'lower'; category.move_lower
      when 'lowest'; category.move_to_bottom
      end if params[:position]
      redirect_to :controller => 'term_categories', :action => 'index', :project_id => @project
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def destroy
    @category = TermCategory.find_by(project_id: @project.id, id: params[:id])
    @term_count = @category.terms.size
    if @term_count == 0
      @category.destroy
      redirect_to :controller => 'term_categories', :action => 'index', :project_id => @project
    elsif params[:todo]
      reassign_to = TermCategory.find_by(project_id: @project.id, id: params[:reassign_to_id]) if params[:todo] == 'reassign'
      @category.destroy(reassign_to)
      redirect_to :controller => 'term_categories', :action => 'index', :project_id => @project
    end
    @categories = TermCategory.where(project_id: @project.id) - [@category]
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
private
  def find_project   
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def conditions_projects()
    ary = authorized_projects(@glossary_style.project_scope, @project,
                              {:controller => :term_categories, :action => :edit})
    return nil	if ary.empty?
    return ary.collect{|proj| "project_id = #{proj.id}" }.join(" OR ")
  end

end
