require "rails_helper"
require "fugit"

RSpec.describe "config/recurring.yml" do
  let(:tasks) { YAML.load_file(Rails.root.join("config/recurring.yml")).fetch("production") }

  it "gives every production task a schedule solid queue can parse" do
    tasks.each do |name, task|
      expect(Fugit.parse_cronish(task.fetch("schedule"))).to be_a(Fugit::Cron), "#{name} has an invalid schedule"
    end
  end

  it "points every job task at a job class" do
    tasks.values.filter_map { |task| task["class"] }.each do |class_name|
      expect(class_name.constantize).to be < ApplicationJob
    end
  end

  it "flags expiring lots every morning" do
    expect(tasks.fetch("flag_expiring_lots")).to eq("class" => "FlagExpiringLotsJob", "schedule" => "every day at 6am")
  end
end
