class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "library@example.com")
  layout "mailer"
end
