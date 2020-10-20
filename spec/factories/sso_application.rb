FactoryBot.define do
  factory :sso_application do
    sequence(:name){ |n| "SSO Application #{n}" }
  end
end
