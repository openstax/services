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

    outputs[:user] = User.create do |user|
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
    return username if username_is_valid?(username) && User.new(username: username).username_is_unique?

    username_max_attempts = 10

    username_max_attempts.times do
      username = User.new.create_random_username(7)
      return username if User.new(username: username).username_is_unique?
    end

    raise "could not create a unique username after #{username_max_attempts} tries"
  end

  def username_is_valid?(username)
    user = User.new(username: username)
    user.valid?
    user.errors[:username].none?
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
