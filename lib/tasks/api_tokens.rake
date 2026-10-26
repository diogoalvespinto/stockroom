namespace :api_tokens do
  desc "Create an API token for a user and print it once (EMAIL=ana@example.com NAME=integration)"
  task create: :environment do
    user = User.find_by!(email_address: ENV.fetch("EMAIL"))
    puts user.api_tokens.create!(name: ENV.fetch("NAME", "default")).token
  end
end
