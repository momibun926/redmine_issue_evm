class GlossaryStylesController < ApplicationController
  unloadable

  helper :glossary_styles
  include GlossaryStylesHelper

  def search
    newparams = {
      :controller => 'glossary', :action => 'index', :id => params[:id]
    }
    unless (params[:search_clear])
      for prm in [:search_category, :search_str, :latest_days]
	if (params[prm] and !params[prm].empty?)
          if (prm == :latest_days and !(params[prm] =~ /^\d+$/))
            flash[:warning] = sprintf(l(:error_to_number), params[prm])
          else
            newparams[prm] = params[prm]
          end
        end
      end
    end
    redirect_to(newparams)
  end


  def edit
    if (User.current.anonymous?)
      if (params[:clear])
        session[:glossary_style] = nil
      else
        session[:glossary_style] = params[:glossary_style]
      end
    else
      unless params[:glossary_style_id].blank?
        @glossary_style = GlossaryStyle.find(params[:glossary_style_id])
      end

      if (@glossary_style)
        if (params[:clear])
          @glossary_style.set_default!
        else
          params[:glossary_style].each {|key,val|
            @glossary_style[key] = val
          }
        end
      else
        @glossary_style = GlossaryStyle.new(params[:glossary_style])
      end

      @glossary_style.user_id = User.current.id
      unless @glossary_style.save
        flash[:error] = l(:notice_glossary_style_create_f)
      end
    end
    newparams = {:controller => 'glossary', :action => 'index',
                :id => params[:id],
                 :glossary_style_id => @glossary_style_id}
    add_search_params(newparams)
    redirect_to(newparams)
  end
end
