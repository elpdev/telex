class CreateEmailSignaturesAndTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :email_signatures do |t|
      t.references :domain, null: false, foreign_key: true
      t.string :name, null: false
      t.boolean :is_default, null: false, default: false

      t.timestamps
    end

    add_index :email_signatures,
      :domain_id,
      unique: true,
      where: "is_default = 1",
      name: "index_default_signature_per_domain"

    create_table :email_templates do |t|
      t.references :domain, null: false, foreign_key: true
      t.string :name, null: false
      t.string :subject

      t.timestamps
    end

    add_index :email_templates, [:domain_id, :name], unique: true
  end
end
