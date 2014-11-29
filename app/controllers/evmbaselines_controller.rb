class EvmbaselinesController < ApplicationController
  unloadable

  menu_item :issueevm

  def index
    @evm_baselines = Evmbaseline.where('id = ? ', params[:id] )
  end

  def new
  end

  def edit
  end

  def create
  end

  def destroy
    @evm_baselines.destroy
  end

end
