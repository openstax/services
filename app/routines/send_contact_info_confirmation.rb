class SendContactInfoConfirmation

  lev_routine

  protected

  def exec(contact_info:, send_pin: false)
    return if contact_info.verified

    contact_info.confirmation_code = SecureRandom.hex(32)
    contact_info.confirmation_pin = SecureRandom.random_number(1000000).to_s.rjust(6,"0") if send_pin

    case contact_info.type
    when 'EmailAddress'
      if contact_info.user.is_unclaimed?
        UnclaimedUserMailer.welcome(contact_info).deliver
      else
        ConfirmationMailer.instructions(email_address: contact_info, send_pin: send_pin).deliver
      end
    else
      fatal_error(code: :not_yet_implemented, data: contact_info)
    end

    contact_info.confirmation_sent_at = Time.now
    contact_info.save

    transfer_errors_from(contact_info, {type: :verbatim})
  end

end
