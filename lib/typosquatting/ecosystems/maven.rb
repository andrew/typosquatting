# frozen_string_literal: true

module Typosquatting
  module Ecosystems
    class Maven < Base
      def initialize
        super
        @purl_type = "maven"
      end

      def name_pattern
        /\A[a-zA-Z0-9._-]+:[a-zA-Z0-9._-]+\z/
      end

      def allowed_characters
        /[a-zA-Z0-9._:-]/
      end

      def allowed_delimiters
        %w[- _ .]
      end

      def case_sensitive?
        true
      end

      def supports_namespaces?
        true
      end

      def normalise(name)
        name
      end

      def parse_namespace(name)
        parts = name.split(":", 2)
        if parts.length == 2
          [parts[0], parts[1]]
        else
          [nil, name]
        end
      end

      def valid_name?(name)
        return false if name.nil? || name.empty?

        group_id, artifact_id = parse_namespace(name)
        return false if group_id.nil? || artifact_id.nil?
        return false if group_id.empty? || artifact_id.empty?

        group_valid = group_id =~ /\A[a-zA-Z0-9._-]+\z/
        artifact_valid = artifact_id =~ /\A[a-zA-Z0-9._-]+\z/

        group_valid && artifact_valid
      end

      def format_name(group_id, artifact_id)
        "#{group_id}:#{artifact_id}"
      end
    end

    Base.register(Maven.new)
  end
end
