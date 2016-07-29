# Copyright 2011-2012 Rice University. Licensed under the Affero General Public
# License version 3 or later.  See the COPYRIGHT file for details.

module Admin
  class BaseController < ApplicationController

    include FakeExceptionHelper

    if Rails.env.development?
      skip_before_filter :authenticate_user!
      skip_before_filter :finish_sign_up

      fine_print_skip :general_terms_of_use, :privacy_policy
    else
      before_filter :authenticate_admin!
      before_filter :log_out_inactive_admins
    end

    def log_out_inactive_admins
      if current_user.is_administrator?
        if session[:last_admin_activity].to_time <= 30.minutes.ago
          sign_out!
          authenticate_admin!
        else
          session[:last_admin_activity] = DateTime.now.to_s
        end
      end
    end

    def cron
      Ost::Cron::execute_cron_jobs
      flash[:notice] = "Ran cron tasks"
      redirect_to admin_path
    end

    def raise_exception
      raise_fake_exception(params[:type])
    end

  end
end
