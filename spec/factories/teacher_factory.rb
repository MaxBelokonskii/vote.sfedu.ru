FactoryBot.define do
  factory :teacher do
    external_id { Faker::Russian.snils }
    name { Faker::Name.name }
    snils { Faker::Russian.snils }
    enabled { true }
    kind { :common }
    origin { :imported }

    after(:create) do |teacher|
      teacher.encrypt_snils!
      teacher.reload
    end

    trait :manual do
      origin { :manual }
      external_id { nil }
    end

    trait :deleted do
      deleted_at { Time.current }
    end
  end
end
