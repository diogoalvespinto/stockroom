RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, :js, type: :system) do
    driven_by :selenium, using: ENV["SHOW_BROWSER"] ? :chrome : :headless_chrome, screen_size: [ 1400, 900 ]
  end
end
