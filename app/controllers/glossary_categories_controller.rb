class GlossaryCategoriesController < ApplicationController

  before_action :find_category_from_id, only: [:show, :edit, :update, :destroy]
  before_action :find_project_from_id, :authorize
  
  def index
    @categories = GlossaryCategory.where(project_id: @project.id)
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
    category.project = @project
    if category.save
      redirect_to [@project, category], notice: l(:notice_successful_create)
    end
  end

  def update
    @category.attributes = glossary_category_params
    if @category.save
      redirect_to [@project, @category], notice: l(:notice_successful_update)
    end
  rescue ActiveRecord::StaleObjectError
    flash.now[:error] = l(:notice_locking_conflict)
  end

  def destroy
    @category.destroy
    redirect_to project_glossary_categories_path
  end
  
  # Find the category whose id is the :id parameter
  def find_category_from_id
    @category = GlossaryCategory.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  private

  # Find the project whose id is the :project_id parameter
  def find_project_from_id
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def glossary_category_params
    params.require(:glossary_category).permit(
      :name
    )
  end
end
