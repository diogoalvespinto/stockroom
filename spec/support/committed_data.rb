RSpec.shared_context "with committed data" do
  self.use_transactional_tests = false

  after do
    connection = ActiveRecord::Base.connection
    connection.truncate_tables(*(connection.tables - %w[schema_migrations ar_internal_metadata]))
  end
end
