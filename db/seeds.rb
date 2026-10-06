admin_password = ENV.fetch("SEED_ADMIN_PASSWORD")
user_password = ENV.fetch("SEED_USER_PASSWORD")

User.find_or_create_by!(email_address: ENV.fetch("SEED_ADMIN_EMAIL")) do |user|
  user.name = "ผู้ดูแลระบบ"
  user.role = "admin"
  user.password = admin_password
end

[
  { name: "สมชาย ใจดี", email_address: "somchai@example.com" },
  { name: "สมหญิง รักงาน", email_address: "somying@example.com" }
].each do |attributes|
  User.find_or_create_by!(email_address: attributes[:email_address]) do |user|
    user.name = attributes[:name]
    user.role = "user"
    user.password = user_password
  end
end
