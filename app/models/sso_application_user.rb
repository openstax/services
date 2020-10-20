class SsoApplicationUser < ActiveRecord::Base
  belongs_to :user, inverse_of: :sso_application_users
  belongs_to :sso_application, inverse_of: :sso_application_users

end
