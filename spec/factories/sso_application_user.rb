FactoryBot.define do
  factory :sso_application_user do
    association :sso_application, factory: :sso_application
    user { FactoryBot.build(:user, :username => username,
                                    :first_name => first_name,
                                    :last_name => last_name) }
    # unread_updates { 1 }

    transient do
      username { SecureRandom.hex(3) }
      first_name { Faker::Name.first_name }
      last_name  { Faker::Name.last_name }
    end

  end
end
