# Active Operator

A Rails pattern for calling external APIs, then storing and processing their responses.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "active_operator"
```

And then execute:

```bash
bundle install
rails generate active_operator:install
rails db:migrate
```

## Usage

### 1. Define an Operation

Generate an operation class by running `rails generate active_operator:operation [name]`.

```ruby
class Geocoding::V1 < ApplicationOperation
  def request
    # Make API call and return response, which will be stored in the operation record
    faraday.get(
      "https://api.geocod.io/v1.8/geocode",
      {
        q: record.address,
        api_key: Rails.application.credentials.dig(:geocodio, :api_key),
        fields: "timezone"
      }
    )
  end

  def process
    # Load the response stored in the operation record, and update perform updates and other actions
    result = response.dig("body", "results", 0)

    record.update!(
      latitude: result.dig("location", "lat"),
      longitude: result.dig("location", "lng"),
      timezone: result.dig("fields", "timezone", "name")
    )
  end
end
```

### 2. Associate with Models

Use the `has_operation` method in your models:

```ruby
class Location < ApplicationRecord
  has_operation :geocoding, class_name: "Geocoding::V1"
end
```

### 3. Save Operations

You are responsible for saving the associated operation record.

```ruby
# Save an associated operation for a new record, within a transaction
location = Location.new(location_params)
location.build_geocoding
location.save

# Save an associated operation for an existing record
location = Location.find(params[:id])
location.geocoding.save
```

### 4. Perform Operations

```ruby
# Synchronous execution
location = Location.find(params[:id])
location.geocoding.perform

# Asynchronous execution
location = Location.find(params[:id])
location.geocoding.perform_later
```

### 5. Check Operation Status

```ruby
location.geocoding.received?   # Operation completed request and stored response
location.geocoding.processed?  # Operation completed processing of response
location.geocoding.errored?    # Operation failed either request or process
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/test` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jeremysmithco/active_operator.
