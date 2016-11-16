class SignupProfileInstructor

  lev_handler

  paramify :profile do
    attribute :first_name, type: String
    validates :first_name, presence: true
    attribute :last_name, type: String
    validates :last_name, presence: true
    attribute :suffix, type: String

    attribute :phone_number, type: String
    validates :phone_number, presence: true
    attribute :school, type: String
    validates :school, presence: true
    attribute :url, type: String
    validates :url, presence: true
    attribute :num_students, type: String
    validates :num_students, presence: true
    attribute :using_openstax, type: String
    validates :using_openstax, presence: true
    attribute :newsletter, type: boolean

    attribute :contract_1_id, type: Integer
    attribute :contract_2_id, type: Integer
  end

  def authorized?
    caller.is_needs_profile?
    # OSU::AccessPolicy.action_allowed?(:signup, caller, caller)  # TODO was this before
  end

  def handle
    # Set profile info on user and set to activated

    caller.first_name           = profile_params.first_name
    caller.last_name            = profile_params.last_name
    caller.suffix               = profile_params.suffix      if !profile_params.suffix.blank?
    caller.state                = 'activated'
    caller.self_reported_school = profile_params.school

    caller.save

    # Agree to terms
    if options[:contracts_required]
      run(AgreeToTerms, profile_params.contract_1_id, caller, no_error_if_already_signed: true)
      run(AgreeToTerms, profile_params.contract_2_id, caller, no_error_if_already_signed: true)
    end

    # TODO check if enabled to push Leads
    PushSalesforceLead.perform_later(
      user: caller,
      role: options[:role],
      phone_number: profile_params.phone_number,
      school: caller.self_reported_school,
      num_students: profile_params.num_students,
      using_openstax: profile_params.using_openstax,
      url: profile_params.url,
      newsletter: profile_params.newsletter
    )
  end

end
