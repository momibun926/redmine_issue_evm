class GlossaryTermsController < ApplicationController

  before_action :find_term_from_id, only: [:show, :edit, :update, :destroy]
  before_action :find_project_from_id, only: [:index, :create]
                  
  def index
    @glossary_terms = GlossaryTerm.where(project_id: @project.id)
  end

  def new
    @term = GlossaryTerm.new
  end

  def create
    term = GlossaryTerm.new(glossary_term_params)
    term.project = @project
    if term.save
      redirect_to term, notice: l(:notice_successful_create)
    end
  end

  def edit
  end

  def update
    @term.attributes = glossary_term_params
    if @term.save
      redirect_to @term, notice: l(:notice_successful_update)
    end
  rescue ActiveRecord::StaleObjectError
    flash.now[:error] = l(:notice_locking_conflict)
  end

  def destroy
    project = @term.project
    @term.destroy
    redirect_to project.nil? ? home_path : project_glossary_terms_path(project)
  end
  
  # Find the term whose id is the :id parameter
  def find_term_from_id
    @term = GlossaryTerm.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Find the project whose id is the :project_id parameter
  def find_project_from_id
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
    
  private

  def glossary_term_params
    params.require(:glossary_term).permit(
      :name, :description, :category_id
    )
  end
end
