# frozen_string_literal: true

require "csv"
require "open-uri"

class ListingImportService
  VALID_PRODUCT_NAME = "Long Term Office - 1 Workstation"
  ACTIVE = "ACTIVE"

  SUCCESS = "success"
  PARTIAL_SUCCESS = "partial_success"

  class << self
    delegate :call, to: :new
  end

  def call(csv_url)
    fetch_csv(csv_url)
    parse_csv
    upsert_listings
    [status, @invalid_rows]
  end

  private

  def fetch_csv(csv_url)
    url = URI.parse(csv_url)

    raise URI::InvalidURIError unless url.is_a?(URI::HTTPS)

    @csv = url.open.read
  end

  def parse_csv
    @listings = []
    @invalid_rows = []
    CSV.parse(@csv, headers: true) do |row|
      next unless skip?(row)

      unless valid?(row)
        @invalid_rows << row
        next
      end

      @listings << {
        source_identifier: source_identifier_for(row),
        street_address: row["address_line1"],
        suite_number: row["suite_numbers"],
        city: row["city"],
        postal_code: row["zip_or_postal_code"],
        listing_description: row["building_description"],
        building_description: row["local_area_description"],
        minimum_size: 80,
        maximum_size: 1100,
        minimum_term: 1,
        base_rent_per_month: BigDecimal(row["min_cost"]) / 80 * 12,
        status: row["center_status"],
        building_size: sqm_to_sqft(row["total_building_size"]),
      }
    end
  end

  def source_identifier_for(row)
    "#{row["centre_id"]}-#{row["product_name"]}"
  end

  def skip?(row)
    row["product_name"] == VALID_PRODUCT_NAME && row["center_status"] == ACTIVE
  end

  def valid?(row)
    @listings.none? { |l| l[:source_identifier] == source_identifier_for(row) } &&
      row["address_line1"].present? &&
      BigDecimal(row["min_cost"]).finite? &&
      (row["total_building_size"].blank? || BigDecimal(row["total_building_size"]).finite?)
  rescue ArgumentError, TypeError
    false
  end

  def sqm_to_sqft(val)
    return if val.blank?

    sqm = BigDecimal(val)

    sqm * 10.764 if sqm.finite?
  end

  def upsert_listings
    # rubocop:disable Rails::SkipsModelValidations
    Listing.upsert_all(@listings, unique_by: :source_identifier)
    # rubocop:enable Rails::SkipsModelValidations
  end

  def status
    # rubocop:disable Rails/HelperInstanceVariable
    return PARTIAL_SUCCESS if @invalid_rows.present?
    # rubocop:enable Rails/HelperInstanceVariable

    SUCCESS
  end
end
