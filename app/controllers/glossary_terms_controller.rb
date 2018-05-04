class GlossaryTermsController < ApplicationController

  before_action :find_term_from_id, only: [:show]
  
  def index
    @glossary_terms = GlossaryTerm.all
  end

#  def show

#  end

  # Find the term whose id is the :id parameter
  def find_term_from_id
    @term = GlossaryTerm.find(params[:id])
  end
end
