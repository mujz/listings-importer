# frozen_string_literal: true

require "rails_helper"

RSpec.describe(ListingImportService, type: :service) do
  subject(:result) do
    status, invalid_rows = call
    { status: status, invalid_rows: invalid_rows }
  end

  let(:call) { described_class.call(url) }

  context "when url is valid" do
    # rubocop:disable RSpec/AnyInstance
    before do
      allow_any_instance_of(URI::HTTPS)
        .to receive(:open) { |_| csv_file }
        .once
    end
    # rubocop:enable RSpec/AnyInstance

    let(:url) { "https://some-fake-url.com/file.csv" }
    let(:csv_file) { file_fixture("pdsfeed.csv") }

    it "creates 2 new listings" do
      expect { call }.to change(Listing, :count).by(2)
    end

    context "when all listings are new" do
      it "returns success status" do
        expect(result[:status]).to eq("success")
      end

      it "does not create inactive listing" do
        call
        expect(Listing.find_by(source_identifier: "inactive-Long Term Office - 1 Workstation")).to be_nil
      end

      it "does not create listings that are not Long Term Office - 1 Workstation" do
        call
        expect(Listing.find_by(source_identifier: "wrong product name-Long Term Office - 1 Workstation")).to be_nil
      end

      # rubocop:disable RSpec/ExampleLength
      it "creates the first valid row with expected values" do
        call
        expect(Listing.first.attributes.symbolize_keys).to include({
          street_address: "5201 Blue Lagoon Drive",
          suite_number: nil,
          city: "Miami",
          postal_code: "33126",
          listing_description: "building 1 description",
          building_description: "local area 1 description",
          minimum_size: 80,
          maximum_size: 1100,
          minimum_term: 1,
          base_rent_per_month: 50.25,
          status: "ACTIVE",
          building_size: 324511.56,
        })
      end

      it "creates the second valid row with expected values" do
        call
        expect(Listing.last.attributes.symbolize_keys).to include({
          street_address: "Crescent VI",
          suite_number: "21",
          city: "Greenwood Village",
          postal_code: "80111",
          listing_description: "building 3 description",
          building_description: "local area 3 description",
          minimum_size: 80,
          maximum_size: 1100,
          minimum_term: 1,
          base_rent_per_month: 23.25,
          status: "ACTIVE",
          building_size: 145446.67,
        })
      end
      # rubocop:enable RSpec/ExampleLength
    end

    context "when a listing had already been created before" do
      subject(:listing) do
        Listing.create(
          source_identifier: "second valid-Long Term Office - 1 Workstation",
          street_address: "old street address",
          suite_number: "99",
          listing_description: "old building 3 old description",
          building_description: "old local area 3 old description",
          minimum_size: 80,
          maximum_size: 1100,
          minimum_term: 1,
          base_rent_per_month: 100,
          status: "ACTIVE",
          building_size: 1000,
        )
      end

      before { listing }

      it "returns success status" do
        expect(result[:status]).to eq("success")
      end

      # rubocop:disable RSpec/ExampleLength
      it "updates its attributes to match the CSV" do
        expect do
          call
          listing.reload
        end
          .to change(listing, :street_address).to("Crescent VI")
          .and change(listing, :suite_number).to("21")
          .and change(listing, :city).to("Greenwood Village")
          .and change(listing, :postal_code).to("80111")
          .and change(listing, :listing_description).to("building 3 description")
          .and change(listing, :building_description).to("local area 3 description")
          .and change(listing, :base_rent_per_month).to(23.25)
          .and change(listing, :building_size).to(145446.67)
      end
      # rubocop:enable RSpec/ExampleLength
    end

    context "when some of the rows have missing or invalid data" do
      let(:csv_file) { file_fixture("pdsfeed-with-errors.csv") }

      it "returns partial_success status" do
        expect(result[:status]).to eq("partial_success")
      end

      it "creates only 2 listings" do
        expect { call }.to change(Listing, :count).by(2)
      end

      it "creates the valid row" do
        call
        expect(Listing.find_by(source_identifier: "valid-Long Term Office - 1 Workstation")).to be_present
      end

      it "creates the row with an empty total_building_size" do
        call
        listing = Listing.find_by(source_identifier: "total_building_size is empty-Long Term Office - 1 Workstation")
        expect(listing).to be_present
      end

      it "returns the invalid rows" do
        expect(result[:invalid_rows].count).to eq(6)
      end
    end

    context "when a row is duplicated" do
      let(:csv_file) { file_fixture("pdsfeed-with-duplicate-rows.csv") }

      it "returns partial_success status" do
        expect(result[:status]).to eq("partial_success")
      end

      it "creates only 1 listing" do
        expect { call }.to change(Listing, :count).by(1)
      end

      it "creates the first row" do
        call
        expect(Listing.last.city).to eq("first row's city")
      end

      it "returns the duplicate row in invalid_rows" do
        expect(result[:invalid_rows].last["city"]).to eq("second row's city")
      end
    end
  end

  context "when url is http" do
    let(:url) { "http://some-fake-url.com/file.csv" }

    it "raises an error" do
      expect { call }.to raise_error(URI::InvalidURIError)
    end
  end

  context "when url is invalid" do
    let(:url) { "some non-url string" }

    it "raises an error" do
      expect { call }.to raise_error(URI::InvalidURIError)
    end
  end

  context "when url points to a non-existent https page" do
    let(:url) { "https://no-real-website-has-this-url.something-non-existent" }

    it "raises an error" do
      expect { call }.to raise_error(Socket::ResolutionError)
    end
  end
end
