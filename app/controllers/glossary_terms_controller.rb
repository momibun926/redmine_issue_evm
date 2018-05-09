class GlossaryTermsController < ApplicationController

  before_action :find_term_from_id, only: [:show, :edit, :update, :destroy]
  
  def index
    @glossary_terms = GlossaryTerm.all
  end

  def new
    @term = GlossaryTerm.new
  end

  def create
    term = GlossaryTerm.new(glossary_term_params)
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
    @term.destroy
    redirect_to glossary_terms_path
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
      :name, :description, :category_id
    )
  end
end
