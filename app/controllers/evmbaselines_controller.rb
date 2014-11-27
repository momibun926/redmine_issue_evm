class EvmbaselinesController < ApplicationController
  unloadable

  menu_item :issueevm

  def index
    @eb = Evmbaseline.where('project_id = ? ',params[:id])
  end

  def new
  end

  def edit
  end

  def create
  end

  def destroy
  end
end
