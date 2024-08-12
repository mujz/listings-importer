# Listings Importer

This service fetches, transforms, and persists real estate listings from an external CSV source into the database.

## How to Run

### With Docker

1. Create `.env` and `.env.test` files by copying the content of `.env.example` and
   adjusting it as necessary.
1. Start the Rails and the Postgres containers using docker-compose
   ```bash
   docker-compose up -d
   ```
1. Install dependencies
   ```bash
   docker exec -it listings-importer_app_1 gem update
   ```
   ```bash
   docker exec -it listings-importer_app_1 bundle
   ```
1. Run migrations and create testing db
   ```bash
   docker exec -it listings-importer_app_1 bin/rails db:migrate
   ```
   ```bash
   docker exec -it -e RAILS_ENV=test listings-importer_app_1 bin/rails db:prepare
   ```
1. Run rake task for importing listings
   ```bash
   docker exec -it listings-importer_app_1 bin/rake listing:import
   ```
1. You can also run linting and tests using:
   ```bash
   docker exec -it listings-importer_app_1 bin/rubocop
   ```
   ```bash
   docker exec -it listings-importer_app_1 bin/rspec
   ```

### Without Docker

I recommend using the docker setup as it makes things easier to run, however if you
really want to run without docker, you can:

1. Install Ruby and Postgres on your machine, by by following the instructions for your OS.
1. Update `.env` and `.env.test` using your local Postgres installation connection URL.
1. The rest of the steps should be the same as explained in the "[How to Run - With Docker](#with-docker)" section, just the commands will be run without the `docker exec -it listings-importer_app_1` part. For example:
   ```bash
   # instead of
   docker exec -it listings-importer_app_1 bin/rails db:migrate
   # use
   bin/rails db:migrate
   ```

## Technical Implementation

Running `bin/rake listing:import` will call the [ListingImportService](app/services/listing_import_service.rb) with the URL of a CSV file. This service does the following:

1. Fetch the content of the CSV file from the URL
1. Parse the CSV
1. Traverse each row of the CSV and does the following:
  1. If the `center_status` is not "ACTIVE" or `product_name` is not "Long Term Office - 1 Workstation", it is skipped.
  1. If the row has invalid data (for example, if `min_cost` is not a number) it will
     be skipped and marked as invalid.
  1. If there are multiple rows with the same `centre_id` and `product_name`, only
     the first one is created and the rest are marked as invalid.
  1. Otherwise, the row's data is transformed to match the schema of the DB.
1. Finally, all the transformed rows are inserted in bulk into the DB with one query.

If the import completed successfully with no errors, the output status is "success".
However, if at least one row had invalid or incomplete data, the output status is
"partial_success" and the invalid rows can be found in
`log/listing_import_task_invalid_rows.csv`.

If there's an error with the CSV URL or something else unexpected, for example during
data insertion, then the entire service fails and raises the exception it
encountered. This means no rows were imported.

## Technical Decisions

1. The business logic is implemented in a service, making it easier to run to the
   code from a rake task, a background job, or even a controller if that is added in the
   future.
1. Linting is enforced using Spotify's code style.
1. I used `upsert_all`, which does a bulk insert/update of the data all in one query,
   which is much faster than inserting each row in a separate DB query. However, this
   comes with a few caveats:
   1. If there's a huge number of rows being inserted all in one big query, it could
      result in the DB being overloaded. This should be fine when the DB is not
      serving a web server traffic, as latency is not an issue. If this become a
      problem, it could easily be remedied by batching the bulk inserts into
      reasonable batch sizes.
    1. If one row fails the DB validations, the entire upsert fails and none of the
       rows are inserted/updated.
1. Specs were written only for the service, which contains the main business logic.
   If this was a production app, I'd probably write some basic specs for the rake
   task as well.
1. Some of the validations enforced on the DB level were arbitrary, for example
   requiring a street address, but not requiring a city. These can be fine-tuned
   according to the business need.
