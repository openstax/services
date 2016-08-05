# Creates a user with the supplied parameters.
#
# If :ensure_no_errors is true, the routine will make sure that the
# username is available (blank/nil usernames are allowed in this case)
#
# If :ensure_no_errors is not set, the returned user object may have errors
# and if so will not be saved.
class CreateUser
  lev_routine

  protected

  def exec(username:, title: nil, first_name: nil, last_name: nil,
           suffix: nil, full_name: nil, state:, ensure_no_errors: false)

    if ensure_no_errors
      username = generate_unique_valid_username(username)
    end

    create_method = ensure_no_errors ? :create! : :create
    outputs[:user] = User.send(create_method) do |user|
      user.username = username
      user.first_name = first_name.present? ? first_name : guessed_first_name(full_name)
      user.last_name = last_name.present? ? last_name : guessed_last_name(full_name)
      user.title = title
      user.suffix = suffix
      user.state = state
    end

    transfer_errors_from(outputs[:user], {type: :verbatim})
  end

  def generate_unique_valid_username(username)
    return username if User.username_is_valid?(username)

    username_max_attempts = 10

    username_max_attempts.times do
      username = User.create_random_username(base: "user", num_digits_in_suffix: 7)
      return username if User.username_is_valid?(username)
    end

    raise "could not create a unique username after #{username_max_attempts} tries"
  end

  def guessed_first_name(full_name)
    return nil if full_name.blank?
    full_name.split("\s")[0]
  end

  def guessed_last_name(full_name)
    return nil if full_name.blank?
    full_name.split("\s").drop(1).join(' ')
  end
end
