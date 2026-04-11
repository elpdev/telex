class AddSearchColumnsToMessages < ActiveRecord::Migration[8.1]
  def up
    add_column :messages, :recipient_text, :text, null: false, default: ""
    add_column :messages, :search_text, :text, null: false, default: ""
    add_index :messages, :status

    say_with_time "Backfilling message search columns" do
      Message.reset_column_information

      Message.includes(:rich_text_body, attachments_attachments: :blob).find_each do |message|
        message.refresh_search_index!
      end
    end
  end

  def down
    remove_index :messages, :status
    remove_column :messages, :search_text
    remove_column :messages, :recipient_text
  end
end
