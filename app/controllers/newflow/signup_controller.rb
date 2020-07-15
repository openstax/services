module Newflow
  class SignupController < BaseController
    include LoginSignupHelper

    fine_print_skip :general_terms_of_use, :privacy_policy

    before_action :exit_newflow_signup_if_logged_in, only: :welcome

    def verify_email_by_code
      handle_with(
        VerifyEmailByCode,
        success: lambda {
          clear_signup_state
          user ||= @handler_result.outputs.user

          if user.student? || user.is_profile_complete?
            sign_in!(user)
            security_log(:student_verified_email)
            redirect_to signup_done_path
          else
            security_log(:educator_verified_email, user: user)
            save_incomplete_educator(user)
            redirect_to(educator_sheerid_form_path)
          end
        },
        failure: lambda {
          redirect_to(newflow_signup_path)
        }
      )
    end

    def signup_done
      security_log(:user_viewed_signup_form, form_name: action_name)
      @first_name = current_user.first_name
      @email_address = current_user.email_addresses.first&.value
    end

    protected ###############

    def restart_signup_if_missing_incomplete_educator
      redirect_to newflow_signup_path unless current_incomplete_educator.present?
    end

    def exit_newflow_signup_if_logged_in
      if signed_in?
        redirect_back(fallback_location: profile_newflow_path(request.query_parameters))
      end
    end
  end
end
