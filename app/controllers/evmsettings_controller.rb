# setting controller
class EvmsettingsController < BaseevmController
  # menu
  menu_item :issuevm
  # Permission: manage_evmsettings (init.rb)
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
    # find_by, not find: the user who last saved the setting may have been
    # deleted (Redmine does not reassign plugin tables), and the page must
    # still open.
    @update_user = User.find_by(id: @evm_settings.user_id)&.name
  end

  # Update baselie
  #
  def update
    @evm_settings = Evmsetting.find_by(project_id: @project.id)
    @evm_settings.update(evm_setting_params)
    record_updating_user
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

  # Attributes of the setting that the form can change
  PERMITTED_ATTRIBUTES = %i[view_forecast
                            view_version
                            view_performance
                            view_issuelist
                            basis_hours
                            etc_method
                            exclude_holidays
                            region
                            threshold_spi
                            threshold_cpi
                            threshold_cr].freeze
  private_constant :PERMITTED_ATTRIBUTES

  # Record the current user as the one who updated the setting.
  def record_updating_user
    @evm_settings.user_id = User.current.id
    @update_user = User.current.name
  end

  # Strong parameter
  #
  def evm_setting_params
    params.require(:evmsetting).permit(*PERMITTED_ATTRIBUTES)
  end
end
