FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@sfedu.ru" }
    sequence(:nickname) { |n| "user#{n}" }
    sequence(:identity_url) { |n| "https://openid.sfedu.ru/server.php/idpage?user=user#{n}" }
    role { :regular }

    factory :user_with_teacher do
      association :kind, factory: :teacher
    end

    factory :user_with_student do
      association :kind, factory: :student
    end

    factory :admin_user do
      role { :admin }
      association :kind, factory: :student
    end
  end
end
