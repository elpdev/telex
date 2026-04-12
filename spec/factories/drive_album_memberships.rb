FactoryBot.define do
  factory :drive_album_membership do
    association :drive_album

    stored_file { association(:stored_file, user: drive_album.user) }
  end
end
