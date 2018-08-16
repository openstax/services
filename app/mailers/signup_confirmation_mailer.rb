class SignupConfirmationMailer < ApplicationMailer

  def instructions(pre_auth_state:)
    @pre_auth_state = pre_auth_state
    @show_pin = ConfirmByPin.sequential_failure_for(@pre_auth_state).attempts_remaining?

    res = mail to: "#{pre_auth_state.contact_info_value}",
         subject: @show_pin ?
                    "Please confirm your OpenStax account" :
                    "Confirm your email address"

    pre_auth_state.update_column(:confirmation_sent_at, Time.now)
  end
end
