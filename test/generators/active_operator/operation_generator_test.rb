# frozen_string_literal: true

require "test_helper"

require "rails/generators"
require "generators/active_operator/operation_generator"

module ActiveOperator
  module Generators
    class OperationGeneratorTest < Rails::Generators::TestCase
      tests ActiveOperator::Generators::OperationGenerator

      destination File.expand_path("../../tmp", __dir__)
      setup :prepare_destination

      def after_teardown
        FileUtils.rm_rf destination_root
        super
      end

      test "should generate operation file with simple name" do
        run_generator ["user"]

        assert_file "app/operations/user.rb"

        operation_contents = File.read(File.join(destination_root, "app/operations/user.rb"))
        assert_match "class User < ApplicationOperation", operation_contents
        assert_match "def request", operation_contents
        assert_match "def process", operation_contents
      end

      test "should generate operation file with nested directories" do
        run_generator ["geocode/v1/pull"]

        assert_file "app/operations/geocode/v1/pull.rb"

        operation_contents = File.read(File.join(destination_root, "app/operations/geocode/v1/pull.rb"))
        assert_match "class Geocode::V1::Pull < ApplicationOperation", operation_contents
      end

      test "should generate operation file with deeply nested directories" do
        run_generator ["api/v2/users/profile/update"]

        assert_file "app/operations/api/v2/users/profile/update.rb"

        operation_contents = File.read(File.join(destination_root, "app/operations/api/v2/users/profile/update.rb"))
        assert_match "class Api::V2::Users::Profile::Update < ApplicationOperation", operation_contents
      end

      test "should handle operation suffix correctly" do
        run_generator ["user_operation"]

        assert_file "app/operations/user_operation.rb"

        operation_contents = File.read(File.join(destination_root, "app/operations/user_operation.rb"))
        assert_match "class UserOperation < ApplicationOperation", operation_contents
      end

      test "should handle nested operation with operation suffix" do
        run_generator ["geocode/v1/pull_operation"]

        assert_file "app/operations/geocode/v1/pull_operation.rb"

        operation_contents = File.read(File.join(destination_root, "app/operations/geocode/v1/pull_operation.rb"))
        assert_match "class Geocode::V1::PullOperation < ApplicationOperation", operation_contents
      end
    end
  end
end
