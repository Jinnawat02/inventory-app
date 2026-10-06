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

[
  { sku: "PAPER-A4", name: "กระดาษ A4 80 แกรม", unit: "รีม", quantity: 40, low_stock_threshold: 10, description: "กระดาษถ่ายเอกสารขนาด A4" },
  { sku: "PEN-BLUE", name: "ปากกาลูกลื่น สีน้ำเงิน", unit: "ด้าม", quantity: 150, low_stock_threshold: 30 },
  { sku: "PEN-RED", name: "ปากกาลูกลื่น สีแดง", unit: "ด้าม", quantity: 60, low_stock_threshold: 20 },
  { sku: "PENCIL-2B", name: "ดินสอ 2B", unit: "แท่ง", quantity: 80, low_stock_threshold: 20 },
  { sku: "STAPLER-01", name: "เครื่องเย็บกระดาษ", unit: "เครื่อง", quantity: 8, low_stock_threshold: 3 },
  { sku: "STAPLE-10", name: "ลวดเย็บกระดาษ เบอร์ 10", unit: "กล่อง", quantity: 4, low_stock_threshold: 5 },
  { sku: "FOLDER-A4", name: "แฟ้มเอกสาร A4", unit: "เล่ม", quantity: 35, low_stock_threshold: 10 },
  { sku: "TAPE-CLEAR", name: "เทปใส 1 นิ้ว", unit: "ม้วน", quantity: 25, low_stock_threshold: 5 },
  { sku: "TONER-HP26A", name: "ผงหมึก HP 26A", unit: "กล่อง", quantity: 2, low_stock_threshold: 2, description: "สำหรับเครื่องพิมพ์ HP LaserJet Pro" },
  { sku: "BATTERY-AA", name: "ถ่าน AA", unit: "แพ็ค", quantity: 0, low_stock_threshold: 4 }
].each do |attributes|
  Item.find_or_create_by!(sku: attributes[:sku]) do |item|
    item.assign_attributes(attributes)
  end
end
