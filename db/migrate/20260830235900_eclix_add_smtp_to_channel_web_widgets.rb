# Eclixtech fork: per-inbox outgoing SMTP for website inboxes (eclix/patches/0002).
# The version is kept below the schema.rb version on purpose, so a fresh
# schema load marks it as already run and only existing databases migrate.
class EclixAddSmtpToChannelWebWidgets < ActiveRecord::Migration[7.1]
  def change
    change_table :channel_web_widgets, bulk: true do |t|
      t.boolean :smtp_enabled, default: false, null: false
      t.string :smtp_from_email, default: ''
      t.string :smtp_address, default: ''
      t.integer :smtp_port, default: 0
      t.string :smtp_login, default: ''
      t.string :smtp_password, default: ''
      t.string :smtp_domain, default: ''
      t.boolean :smtp_enable_ssl_tls, default: false, null: false
      t.boolean :smtp_enable_starttls_auto, default: true, null: false
      t.string :smtp_openssl_verify_mode, default: 'none'
      t.string :smtp_authentication, default: 'login'
    end
  end
end
