class IdentitiesController < ApplicationController

  skip_before_filter :authenticate_user!, :expired_password, :finish_sign_up,
                     only: [:reset_password]

  fine_print_skip :general_terms_of_use, :privacy_policy,
                  only: [:reset_password]

  def update
    handle_with(IdentitiesUpdate,
                success: lambda  do
                  security_log :password_updated
                  render status: :accepted, text: (I18n.t :"controllers.identities.password_changed")
                end,
                failure: lambda do
                  render status: 400, text: @handler_result.errors.map(&:message).to_sentence
                end)
  end

  def reset_password
    if !current_user.is_anonymous?
      if current_user.identity.nil?
        security_log :password_reset_failed
        flash[:alert] = I18n.t :"controllers.identities.cannot_reset_password_because_user_doesnt_have_one"
        redirect_to profile_path
        return
      end

      if current_user.identity.password_expired?
        security_log :password_expired
        store_fallback key: :password_return_to
        flash[:alert] = I18n.t :"controllers.identities.password_expired"
      end
    end

    handle_with(IdentitiesResetPassword,
                success: lambda do
                  return if !request.post?
                  sign_in! @handler_result.outputs[:identity].user
                  security_log :password_reset
                  security_log :sign_in_successful
                  redirect_back key: :password_return_to,
                                notice: (I18n.t :"controllers.identities.password_reset_successfully")
                end,
                failure: lambda do
                  security_log :password_reset_failed
                  render :reset_password, status: 400
                end)
  end


  def destroy
    handle_with(AuthenticationDelete,
                success: lambda do
                  authentication = @handler_result.outputs.authentication
                  security_log :authentication_deleted,
                               authentication_id: authentication.id,
                               authentication_provider: authentication.provider,
                               authentication_uid: authentication.uid
                  render status: :ok,
                         text: (I18n.t :"controllers.identities.identity_removed",
                                       identity: params[:provider].titleize)
                end,
                failure: lambda do
                  render status: 400, text: @handler_result.errors.map(&:message).to_sentence
                end)
  end

end
