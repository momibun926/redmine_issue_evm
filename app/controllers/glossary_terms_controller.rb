class GlossaryTermsController < ApplicationController

  def index
    @glossary_terms = GlossaryTerm.all
  end
end
