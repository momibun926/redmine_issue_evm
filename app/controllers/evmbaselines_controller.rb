class EvmbaselinesController < ApplicationController
  unloadable

  menu_item :issueevm

  before_filter :find_project, :authorize

  def index
    @evm_baselines = Evmbaseline.where('project_id = ? ', params[:id] )
    @p = params[:id] 
  end

  def new
    @evm_baselines = Evmbaseline.new
  end

  def edit
  end

  def create
    @evm_baselines = Evmbaseline.new(params[:evmbaseline])
    @evm_baselines.project_id = @project.id
    if @evm_baselines.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'index', :id => @project.id
    else
      render :action => 'new'
    end
  end

  def destroy
    @evm_baselines.destroy
  end

private
  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end  
end
