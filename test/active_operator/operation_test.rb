# frozen_string_literal: true

require "test_helper"

module ActiveOperator
  class OperationTest < ActiveSupport::TestCase
    test "#received?" do
      location = create_location
      location.geocoding.save!

      refute location.geocoding.received?
      location.geocoding.touch(:received_at)
      assert location.geocoding.received?
    end

    test "#processed?" do
      location = create_location
      location.geocoding.save!

      refute location.geocoding.processed?
      location.geocoding.touch(:processed_at)
      assert location.geocoding.processed?
    end

    test "#errored?" do
      location = create_location
      location.geocoding.save!

      refute location.geocoding.errored?
      location.geocoding.touch(:errored_at)
      assert location.geocoding.errored?
    end

    test "#perform succeeds on valid request and process" do
      with_operation_methods(Geocoding::V2, GeocodingValid) do
        location = create_location

        assert_nil location.latitude
        assert_nil location.longitude
        assert_nil location.timezone
        assert_nil location.geocoding.received_at
        assert_nil location.geocoding.processed_at

        location.geocoding.perform

        assert_equal 40.59806, location.latitude
        assert_equal -74.68148, location.longitude
        assert_equal "America/New_York", location.timezone
        assert_not_nil location.geocoding.received_at
        assert_not_nil location.geocoding.processed_at
      end
    end

    test "#perform with force succeeds when already received and processed" do
      with_operation_methods(Geocoding::V2, GeocodingValid) do
        location = create_location

        first_time = 5.minutes.ago
        location.geocoding.update!(received_at: first_time, processed_at: first_time)

        assert_not_nil location.geocoding.received_at
        assert_not_nil location.geocoding.processed_at

        location.geocoding.perform(force: true)

        assert_equal 40.59806, location.latitude
        assert_equal -74.68148, location.longitude
        assert_equal "America/New_York", location.timezone
        assert location.geocoding.received_at.after?(first_time)
        assert location.geocoding.processed_at.after?(first_time)
      end
    end

    test "#perform fails on invalid request" do
      with_operation_methods(Geocoding::V2, GeocodingInvalidRequest) do
        location = create_location
        assert_nil location.geocoding.errored_at

        assert_raise(NoMethodError) do
          location.geocoding.perform

          assert_not_nil location.geocoding.errored_at
        end
      end
    end

    test "#perform fails on failed request" do
      with_operation_methods(Geocoding::V2, GeocodingFailedRequest) do
        location = create_location
        assert_nil location.geocoding.errored_at

        assert_raise(GeocodingFailedRequest::RequestError) do
          location.geocoding.perform

          assert_not_nil location.geocoding.errored_at
        end
      end
    end

    test "#perform fails on failed process" do
      with_operation_methods(Geocoding::V2, GeocodingFailedProcess) do
        location = create_location
        assert_nil location.geocoding.errored_at

        assert_raise(ActiveRecord::RecordInvalid) do
          location.geocoding.perform

          assert_not_nil location.geocoding.errored_at
        end
      end
    end

    test "#perform fails when operation methods not defined" do
      location = create_location
      assert_nil location.geocoding.errored_at

      assert_raise(NotImplementedError) do
        location.geocoding.perform

        assert_not_nil location.geocoding.errored_at
      end
    end

    test "#perform_later" do
      location = create_location
      location.geocoding.save!

      assert_enqueued_with job: ActiveOperator::PerformOperationJob, args: [location.geocoding, { force: false }] do
        location.geocoding.perform_later
      end
    end

    test "#perform_later with force" do
      location = create_location
      location.geocoding.save!

      assert_enqueued_with job: ActiveOperator::PerformOperationJob, args: [location.geocoding, { force: true }] do
        location.geocoding.perform_later(force: true)
      end
    end
  end
end
