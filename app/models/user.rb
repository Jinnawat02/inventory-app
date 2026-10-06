class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  enum :role, { user: "user", admin: "admin" }, default: "user", validate: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :name, with: ->(n) { n.strip }

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
