namespace :contacts do
  desc "Backfill contacts and communications from existing messages"
  task backfill: :environment do
    result = Contacts::Backfill.call

    puts "Backfilled contacts"
    puts "Inbound messages processed: #{result.inbound_messages}"
    puts "Outbound messages processed: #{result.outbound_messages}"
    puts "Contacts created: #{result.contacts}"
  end
end
