class Email::ReplyToBuilder < Email::BaseBuilder
  pattr_initialize [:inbox!, :message!]

  def build
    reply_to = if inbox.email?
                 channel.email
               elsif inbound_email_enabled?
                 "reply+#{conversation.uuid}@#{account.inbound_email_domain}"
               elsif inbox.web_widget? && channel.smtp_enabled
                 channel.smtp_from_email
               else
                 account_support_email
               end

    sender_name(reply_to)
  end

  private

  def inbound_email_enabled?
    account.feature_enabled?('inbound_emails') && account.inbound_email_domain.present?
  end
end
