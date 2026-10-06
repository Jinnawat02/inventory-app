require "test_helper"

class MailerPreviewsTest < ActionMailer::TestCase
  test "there is a preview for every order email" do
    previews = OrderMailerPreview.emails

    assert_includes previews, "new_request"
    %w[approved rejected fulfilled].each do |status|
      assert_includes previews, "status_changed_#{status}"
    end
  end

  test "every mailer preview renders" do
    ActionMailer::Preview.all.each do |preview|
      preview.emails.each do |email_name|
        message = preview.call(email_name)

        assert message.to.present?, "#{preview.preview_name}##{email_name} has no recipients"
        assert message.subject.present?, "#{preview.preview_name}##{email_name} has no subject"
        assert message.html_part.decoded.present?, "#{preview.preview_name}##{email_name} has no HTML body"
        assert message.text_part.decoded.present?, "#{preview.preview_name}##{email_name} has no text body"
      end
    end
  end
end
