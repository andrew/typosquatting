# frozen_string_literal: true

module Typosquatting
  module Ecosystems
    class GithubActions < Base
      def initialize
        super
        @name = "github_actions"
        @purl_type = "github"
      end

      def name_pattern
        /\A[a-zA-Z0-9][a-zA-Z0-9-]*\/[a-zA-Z0-9._-]+\z/
      end

      def allowed_characters
        /[a-zA-Z0-9._-]/
      end

      def allowed_delimiters
        %w[- _ .]
      end

      def case_sensitive?
        false
      end

      def supports_namespaces?
        true
      end

      def normalise(name)
        name.downcase.sub(/@.*$/, "")
      end

      def parse_namespace(name)
        clean_name = name.sub(/@.*$/, "")
        parts = clean_name.split("/", 2)
        if parts.length == 2
          [parts[0], parts[1]]
        else
          [nil, name]
        end
      end

      def valid_name?(name)
        return false if name.nil? || name.empty?

        clean_name = name.sub(/@.*$/, "")
        owner, repo = parse_namespace(clean_name)

        return false if owner.nil? || repo.nil?
        return false if owner.empty? || repo.empty?

        return false unless valid_owner?(owner)
        return false unless valid_repo?(repo)

        true
      end

      def format_name(owner, repo)
        "#{owner}/#{repo}"
      end

      def valid_owner?(owner)
        return false if owner.length > 39
        return false if owner.start_with?("-")
        return false if owner.end_with?("-")
        return false if owner.include?("--")

        !!(owner =~ /\A[a-zA-Z0-9][a-zA-Z0-9-]*\z/)
      end

      def valid_repo?(repo)
        return false if repo.length > 100
        return false if repo.start_with?(".")

        !!(repo =~ /\A[a-zA-Z0-9._-]+\z/)
      end
    end

    Base.register(GithubActions.new)
  end
end
