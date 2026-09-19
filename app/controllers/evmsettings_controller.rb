# setting controller
class EvmsettingsController < BaseevmController
  # menu
  menu_item :issuevm
  # Before action -- was missing (see the current-state analysis doc,
  # section 13). manage_evmsettings' action list in init.rb had to be fixed
  # in the same change, or this would have blocked :new/:update/:create
  # (they had no permission mapped to them at all beforehand).
  before_action :authorize
  # New setting
  #
  def new
    @evm_settings = Evmsetting.new
  end

  # Edit setting
  #
  def edit
    @evm_settings = Evmsetting.find_by(project_id: @project.id)
    @update_user = User.find(@evm_settings.user_id).name
  end

  # Update baselie
  #
  def update
    @evm_settings = Evmsetting.find_by(project_id: @project.id)
    @evm_settings.update(evm_setting_params)
    @evm_settings.user_id = User.current.id
    @update_user = User.find(@evm_settings.user_id).name
    if @evm_settings.save
      redirect_to project_evms_path
    else
      render :edit
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
      redirect_to project_evms_path
    else
      render :new
    end
  end

  private

  # Strong parameter
  #
  def evm_setting_params
    params.require(:evmsetting).permit(:view_forecast,
                                       :view_version,
                                       :view_performance,
                                       :view_issuelist,
                                       :basis_hours,
                                       :etc_method,
                                       :exclude_holidays,
                                       :region,
                                       :threshold_spi,
                                       :threshold_cpi,
                                       :threshold_cr)
  end
end
