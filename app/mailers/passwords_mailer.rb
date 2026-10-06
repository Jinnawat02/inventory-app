class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: "ตั้งรหัสผ่านใหม่", to: user.email_address
  end
end
