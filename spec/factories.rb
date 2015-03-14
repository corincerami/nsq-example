FactoryGirl.define do
  factory :video do
    sequence(:video_uuid) { |n| "#{n}123-4567" }
  end
end
