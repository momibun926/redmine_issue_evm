class GlossaryTermsController < ApplicationController

  before_action :find_term_from_id, only: [:show, :edit, :update, :destroy]
  before_action :find_project_by_project_id, :authorize
  
  def index
    @glossary_terms = GlossaryTerm.where(project_id: @project.id)
    if not params[:index].nil?
      @glossary_terms = @glossary_terms.search_by_name(params[:index])
    elsif not params[:index_rubi].nil?
      @glossary_terms = @glossary_terms.search_by_rubi(params[:index_rubi])
    end
    @grouping = params[:grouping] unless params[:grouping].nil?
  end

  def new
    @term = GlossaryTerm.new
  end

  def create
    term = GlossaryTerm.new(glossary_term_params)
    term.project = @project
    term.save_attachments params[:attachments]
    if term.save
      render_attachment_warning_if_needed term
      redirect_to [@project, term], notice: l(:notice_successful_create)
    end
  end

  def edit
  end

  def update
    @term.attributes = glossary_term_params
    @term.save_attachments params[:attachments]
    if @term.save
      render_attachment_warning_if_needed @term
      redirect_to [@project, @term], notice: l(:notice_successful_update)
    end
  rescue ActiveRecord::StaleObjectError
    flash.now[:error] = l(:notice_locking_conflict)
  end

  def destroy
    @term.destroy
    redirect_to project_glossary_terms_path
  end
  
  # Find the term whose id is the :id parameter
  def find_term_from_id
    @term = GlossaryTerm.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  private

  def glossary_term_params
    params.require(:glossary_term).permit(
      :name, :description, :category_id,
      :name_en, :rubi, :abbr_whole, :datatype, :codename
    )
  end
end
