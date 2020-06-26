module Newflow
  class StudentSignupController < SignupController
    skip_before_action :restart_signup_if_missing_unverified_user, only: [
      :student_signup_form, :student_signup
    ]

    def student_signup
      handle_with(
        StudentSignup,
        contracts_required: !contracts_not_required,
        client_app: get_client_app,
        user_from_signed_params: session[:user_from_signed_params],
        success: lambda {
          save_unverified_user(@handler_result.outputs.user)
          security_log :student_signed_up, { user: @handler_result.outputs.user }
          redirect_to student_email_verification_form_path
        },
        failure: lambda {
          email = @handler_result.outputs.email
          error_codes = @handler_result.errors.map(&:code)
          security_log(:student_sign_up_failed, { reason: error_codes, email: email })
          render :student_signup_form
        }
      )
    end

    def student_change_signup_email_form
      @email = unverified_user.email_addresses.first.value
    end

    def student_change_signup_email
      handle_with(
        ChangeSignupEmail,
        user: unverified_user,
        success: lambda {
          redirect_to student_email_verification_form_updated_email_path
        },
        failure: lambda {
          @email = unverified_user.email_addresses.first.value
          render :student_change_signup_email_form
        }
      )
    end

    def student_email_verification_form
      @first_name = unverified_user.first_name
      @email = unverified_user.email_addresses.first.value
    end

    def student_email_verification_form_updated_email
      @email = unverified_user.email_addresses.first.value
    end

    def student_verify_email_by_pin
      handle_with(
        VerifyEmailByPin,
        email_address: unverified_user.email_addresses.first,
        success: lambda {
          clear_newflow_state
          user = @handler_result.outputs.user
          sign_in!(user)
          security_log(:student_verified_email)

          redirect_to(signup_done_path)
        },
        failure: lambda {
          @first_name = unverified_user.first_name
          @email = unverified_user.email_addresses.first.value
          security_log(:student_verify_email_failed, email: @email)
          render(:email_verification_form)
        }
      )
    end
  end
end