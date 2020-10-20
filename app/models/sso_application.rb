class SsoApplication < ActiveRecord::Base
  has_many :sso_application_users
  has_many :users, through: :sso_application_users
end
