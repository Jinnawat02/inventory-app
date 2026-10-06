require "test_helper"

class ApplicationMailerTest < ActionMailer::TestCase
  def with_mailer_from(value)
    previous = Rails.configuration.x.mailer_from
    Rails.configuration.x.mailer_from = value
    yield
  ensure
    Rails.configuration.x.mailer_from = previous
  end

  test "emails are sent from the configured sender" do
    with_mailer_from("requisitions@example.test") do
      email = OrderMailer.status_changed(orders(:approved_one), "approved")

      assert_equal [ "requisitions@example.test" ], email.from
    end
  end

  test "sending fails loudly when no sender is configured" do
    with_mailer_from(nil) do
      assert_raises(KeyError) do
        OrderMailer.status_changed(orders(:approved_one), "approved").deliver_now
      end
    end
  end
end
