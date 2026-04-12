FactoryBot.define do
  factory :stored_file do
    transient do
      root_level { false }
    end

    association :user
    sequence(:filename) { |n| "file-#{n}.png" }
    mime_type { "image/png" }
    byte_size { 1024 }
    source { :local }
    image_width { 640 }
    image_height { 480 }
    metadata { {} }

    after(:build) do |stored_file, evaluator|
      stored_file.folder ||= build(:folder, user: stored_file.user) unless evaluator.root_level
    end
  end
end
