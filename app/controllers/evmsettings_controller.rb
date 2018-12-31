# setting controller
class EvmsettingsController < ApplicationController
  unloadable

  # Create of baseline
  #
  def new
    @evm_settings = Evmsetting.new
  end

  # View of setting
  #
  def show
    @evm_settings = Evmsetting.find(params[:id])
  end

  # Edit setting
  #
  def edit
    @evm_settings = Evmsetting.find(params[:id])
  end

  # Update baselie
  #
  def update
    evm_settings = Evmsetting.find(params[:id])
    evm_settings.update_attributes(evm_baseline_params)
    if evm_settings.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to action: :new
    else
      redirect_to action: :edit
    end
  end

  # Create evm setting
  #
  def create
    evm_settings = Evmsetting.new(evm_setting_params)
    # Save
    if evm_settings.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to action: :index
    else
      redirect_to action: :new
    end
  end

  private

    # Strong parameter
    #
    def evm_setting_params
      params.require(:evmsetting).permit(:view_forecast, 
                                         :description)
    end

end
