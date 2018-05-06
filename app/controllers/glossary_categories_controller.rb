class GlossaryCategoriesController < ApplicationController

  before_action :find_category_from_id, only: [:show, :edit, :update, :destroy]
  
  def index
    @categories = GlossaryCategory.all
  end

  def show
  end

  def new
    @category = GlossaryCategory.new
  end

  def edit
  end

  def create
    category = GlossaryCategory.new(glossary_category_params)
    if category.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to category
    end
  end

  def update
    @category.attributes = glossary_category_params
    if @category.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to @category
    end
  rescue ActiveRecord::StaleObjectError
    flash.now[:error] = l(:notice_locking_conflict)
  end

  def destroy
    @category.destroy
    redirect_to glossary_categories_path
  end
  
  # Find the category whose id is the :id parameter
  def find_category_from_id
    @category = GlossaryCategory.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  private
  
  def glossary_category_params
    params.require(:glossary_category).permit(
      :name
    )
  end
end
