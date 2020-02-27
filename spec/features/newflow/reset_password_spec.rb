require 'rails_helper'

require_relative './add_reset_password_shared_examples'

feature 'Password reset', js: true do
  before do
    turn_on_feature_flag
  end

  it_behaves_like "add_reset_password_shared_examples", :reset

  scenario 'while still logged in – user is not stuck in a loop' do
    # shouldn't ask to reauthenticate when they forgot their password and are trying to reset it
    # issue: https://github.com/openstax/business-intel/issues/550
    user = create_newflow_user('user@openstax.org', 'password')
    login_token = generate_login_token_for_user(user)
    newflow_log_in_user('user@openstax.org', 'password')

    Timecop.freeze(Time.now + RequireRecentSignin::REAUTHENTICATE_AFTER) do
      find('[data-provider=identity] .edit--newflow').click
      expect(page).to have_content(I18n.t(:"login_signup_form.login_page_header"))

      click_link(t(:"login_signup_form.forgot_password"))
      expect(page).to have_content(
        strip_html(
          t(:'login_signup_form.password_reset_email_sent_description', email: 'user@openstax.org')
        )
      )

      open_email('user@openstax.org')
      password_reset_link = get_path_from_absolute_link(current_email, 'a')
      visit password_reset_link

      expect(page).not_to(have_current_path(reauthenticate_form_path))
      expect(page).to(have_current_path(change_password_form_path(token: login_token)))
    end
  end

  scenario 'with identity gets redirected to reset password' do
    @user = create_user 'user'
    @login_token = generate_login_token_for 'user'
    visit password_add_path(token: @login_token)
    expect(page).to have_current_path password_reset_path
  end

  scenario "'Forgot password?' link from reauthenticate page sends email (bypassing Reset Password Form)" do
    create_newflow_user('user@openstax.org', 'password')
    newflow_log_in_user('user@openstax.org', 'password')

    Timecop.freeze(Time.now + RequireRecentSignin::REAUTHENTICATE_AFTER) do
      find('[data-provider=identity] .edit--newflow').click
      expect(page).to have_content(I18n.t(:"login_signup_form.login_page_header"))
      click_link(t(:"login_signup_form.forgot_password"))
      expect(page).to have_content(
        strip_html(
          t(:'login_signup_form.password_reset_email_sent_description', email: 'user@openstax.org')
        )
      )
      open_email('user@openstax.org')
      expect(current_email).to have_content('reset')
    end
  end

  scenario 'reset password links stay constant for a fixed time' do
    create_newflow_user('user@openstax.org', 'password')

    visit newflow_login_path
    screenshot!
    newflow_log_in_user('user@openstax.org', 'WRONGpassword')
    screenshot!

    click_on(I18n.t(:"login_signup_form.forgot_password"))
    # pre-populates the email for them since they already typed it in the login form
    expect(find('#forgot_password_form_email')['value']).to  eq('user@openstax.org')
    screenshot!
    click_on(I18n.t(:"login_signup_form.reset_my_password_button"))
    screenshot!

    expect(page).to have_content(I18n.t(:"login_signup_form.password_reset_email_sent"))
    screenshot!

    open_email('user@openstax.org')
    change_password_link_1 = get_path_from_absolute_link(current_email, 'a')
    clear_emails

    visit newflow_login_path
    newflow_log_in_user('user@openstax.org', 'WRONGpassword')
    click_on(I18n.t(:"login_signup_form.forgot_password"))
    # pre-populates the email for them since they already typed it in the login form
    expect(find('#forgot_password_form_email')['value']).to  eq('user@openstax.org')

    click_on(I18n.t(:"login_signup_form.reset_my_password_button"))
    expect(page).to have_content(I18n.t(:"login_signup_form.password_reset_email_sent"))

    open_email('user@openstax.org')
    change_password_link_2 = get_path_from_absolute_link(current_email, 'a')
    clear_emails

    expect(change_password_link_1).to eq(change_password_link_2)

    Timecop.freeze(Time.now + IdentitiesSendPasswordEmail::LOGIN_TOKEN_EXPIRES_AFTER) do
      visit newflow_login_path
      newflow_log_in_user('user@openstax.org', 'WRONGpassword')
      click_on(I18n.t(:"login_signup_form.forgot_password"))
      # pre-populates the email for them since they already typed it in the login form
      expect(find('#forgot_password_form_email')['value']).to  eq('user@openstax.org')

      click_on(I18n.t(:"login_signup_form.reset_my_password_button"))
      expect(page).to have_content(I18n.t(:"login_signup_form.password_reset_email_sent"))

      open_email('user@openstax.org')
      change_password_link_3 = get_path_from_absolute_link(current_email, 'a')
      clear_emails

      expect(change_password_link_2).not_to eq(change_password_link_3)
    end
  end

  scenario 'failure to send reset email sends user back to authenticate page' do
    create_newflow_user('user@openstax.org', 'password')
    visit newflow_login_path
    newflow_log_in_user('user@openstax.org', 'WRONGpassword')
    click_on(I18n.t(:"login_signup_form.forgot_password"))

    # Cause an error to occur in the handler that sends the email
    allow_any_instance_of(User).to receive(:save).and_wrap_original do |original_method, *args, &block|
      original_method.call(*args, &block)
      original_method.receiver.errors.add(:base, "Fake spec error")
    end

    click_on(I18n.t(:"login_signup_form.reset_my_password_button"))

    expect(page.current_path).to eq(newflow_login_path)
    # expect a security log as well
    expect(SecurityLog.where(reason: :reset_password_failed, user: User.last))
  end
end
