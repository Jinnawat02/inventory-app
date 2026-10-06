class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  scope :active, -> { where(active: true) }

  enum :role, { user: "user", admin: "admin" }, default: "user", validate: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :name, with: ->(n) { n.strip }

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :cannot_deactivate_self, if: :deactivating?

  after_update_commit :terminate_sessions, if: -> { saved_change_to_active?(to: false) }

  def role_name
    I18n.t("users.roles.#{role}")
  end

  private
    def deactivating?
      will_save_change_to_active?(to: false)
    end

    def cannot_deactivate_self
      errors.add(:active, :cannot_deactivate_self) if self == Current.user
    end

    def terminate_sessions
      sessions.destroy_all
    end
end
