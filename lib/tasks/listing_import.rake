# frozen_string_literal: true

namespace :listing do
  desc "Import listings from CSV"
  task import: :environment do
    CSV_URL = "https://transport.productsup.io/f3a2e50f7147b3825f50/channel/340023/pdsfeed.csv"
    INVALID_ROWS_CSV_PATH = Rails.root.join("log/listing_import_task_invalid_rows.csv")

    status, invalid_rows = ListingImportService.call(CSV_URL)

    puts "Completed listing import with status: #{status}."

    next if invalid_rows.blank?

    CSV.open(INVALID_ROWS_CSV_PATH, "wb") do |csv|
      invalid_rows.each { |row| csv << row }
    end

    puts "#{invalid_rows.length} rows were invalid. You can see them in #{INVALID_ROWS_CSV_PATH}."
  end
end
