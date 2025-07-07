require 'rails/generators'
require 'active_support/inflector'

module ActiveOperator
  module Generators
    class OperationGenerator < Rails::Generators::NamedBase
      include Rails::Generators::ResourceHelpers

      check_class_collision

      source_root File.expand_path("templates", __dir__)

      desc "Generates an operation with the given NAME."

      def create_operation_file
        template "operation.rb.erb", "app/operations/#{file_path}.rb"
      end
    end
  end
end
