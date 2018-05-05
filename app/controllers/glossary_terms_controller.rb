class GlossaryTermsController < ApplicationController

  before_action :find_term_from_id, only: [:show]
  
  def index
    @glossary_terms = GlossaryTerm.all
  end

  def new
    @term = GlossaryTerm.new
  end

  def create
    term = GlossaryTerm.new(glossary_term_params)
    if term.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to glossary_term_path(term.id)
    end
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
      :name, :description
    )
  end
end
