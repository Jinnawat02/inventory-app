class ApplicationMailer < ActionMailer::Base
  default from: -> { Rails.configuration.x.mailer_from.presence || raise(KeyError, "MAILER_FROM is not set") }
  layout "mailer"
end
