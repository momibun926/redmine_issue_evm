# setting controller
class EvmsettingsController < ApplicationController
  unloadable

  # Before action
  before_action :find_project

  # New setting
  #
  def new
    @evm_settings = Evmsetting.new
  end

  # Edit setting
  #
  def edit
    @evm_settings = Evmsetting.find_by(project_id: @project.id)
    @update_user = User.find(@evm_settings.user_id)
  end

  # Update baselie
  #
  def update
    @evm_settings = Evmsetting.find_by(project_id: @project.id)
    @evm_settings.update(evm_setting_params)
    @evm_settings.user_id = User.current.id
    @update_user = User.find(@evm_settings.user_id)
    if @evm_settings.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_evms_path
    else
      render "edit"
    end
  end

  # Create evm setting
  #
  def create
    @evm_settings = Evmsetting.new(evm_setting_params)
    @evm_settings.project_id = @project.id
    @evm_settings.user_id = User.current.id
    # Save
    if @evm_settings.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_evms_path
    else
      render "new"
    end
  end

  private

    # find project object
    #
    def find_project
      @project = Project.find(params[:project_id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    # Strong parameter
    #
    def evm_setting_params
      params.require(:evmsetting).permit(:view_forecast,
                                         :view_version,
                                         :view_performance,
                                         :view_issuelist,
                                         :basis_hours,
                                         :etc_method,
                                         :region,
                                         :threshold_spi,
                                         :threshold_cpi,
                                         :threshold_cr)
    end
end
