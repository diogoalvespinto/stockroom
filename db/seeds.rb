user = User.find_or_create_by!(email_address: "demo@example.com") { |demo| demo.password = "password" }

warehouses = {
  "LIS" => "Lisbon central store",
  "OPO" => "Porto depot",
  "FAO" => "Faro clinic"
}.to_h { |code, name| [ code, Warehouse.find_or_create_by!(code: code) { |warehouse| warehouse.name = name } ] }

items = [
  [ "GLV-100", "Nitrile gloves (M)", "box", 40 ],
  [ "MSK-200", "Surgical masks", "box", 60 ],
  [ "SYR-050", "Syringes 5 ml", "pack", 30 ],
  [ "SAL-500", "Saline solution 500 ml", "bottle", 24 ],
  [ "BND-010", "Elastic bandages", "roll", 10 ],
  [ "THR-001", "Digital thermometer", "each", 5 ]
].to_h do |sku, name, unit, reorder_level|
  item = Item.find_or_create_by!(sku: sku) do |new_item|
    new_item.assign_attributes(name: name, unit_of_measure: unit, reorder_level: reorder_level)
  end
  [ sku, item ]
end

unless StockMovement.exists?
  today = Date.current
  receive = lambda do |sku, code, lot_number, days_to_expiry, quantity|
    Stock::Receive.call(
      item: items.fetch(sku), warehouse: warehouses.fetch(code), lot_number: lot_number,
      expiry_date: days_to_expiry && today + days_to_expiry, quantity: quantity, user: user
    )
  end

  receive.call("GLV-100", "LIS", "GLV-2501", 12, 30)
  receive.call("GLV-100", "LIS", "GLV-2507", 200, 80)
  receive.call("GLV-100", "OPO", "GLV-2507", 200, 40)
  receive.call("MSK-200", "LIS", "MSK-2410", -5, 25)
  receive.call("MSK-200", "OPO", "MSK-2503", 25, 50)
  receive.call("SYR-050", "LIS", "SYR-2502", 45, 20)
  receive.call("SAL-500", "FAO", "SAL-2504", 6, 18)
  receive.call("BND-010", "FAO", "BND-0001", nil, 25)
  receive.call("THR-001", "LIS", "THR-0001", nil, 3)

  Stock::Issue.call(
    item: items.fetch("GLV-100"), warehouse: warehouses.fetch("LIS"), quantity: 45, reason: "Ward 3 restock", user: user
  )
  Stock::Transfer.call(
    lot: Lot.find_by!(lot_number: "MSK-2503"), from: warehouses.fetch("OPO"), to: warehouses.fetch("FAO"),
    quantity: 10, user: user
  )
  Stock::Adjust.call(
    lot: Lot.find_by!(lot_number: "SYR-2502"), warehouse: warehouses.fetch("LIS"), quantity: -2,
    reason: "Damaged packaging", user: user
  )
end

puts "Seeded #{Warehouse.count} warehouses, #{Item.count} items and #{StockMovement.count} movements."
puts "Sign in as demo@example.com with the password \"password\"."
