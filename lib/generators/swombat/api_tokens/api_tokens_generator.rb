require 'generator_helper'

module Swombat
  module Generators
    class ApiTokensGenerator < Rails::Generators::Base
      include GeneratorHelper

      desc "Sets up an ApiToken system"

      source_root File.expand_path('templates', __dir__)

      def check_not_installed
        say "Checking that ApiTokens is not already installed", :green
        if File.exist?("app/models/api_token.rb")
          say "It looks like ApiTokens is already installed. Aborting.", :red
          exit
        end
      end

      def run_generator
        say "Running generator...", :green
        rails_command "generate super_scaffold ApiToken Team access_token:text_field class_name:super_select"
      end

      def run_migrations
        say "Running migrations...", :green
        unless no?("Run migrations now? (Y/n)", :green)
          rails_command "db:migrate"
        else
          say "Skipping migrations - don't forget to rails db:migrate!", :yellow
        end
      end

      def enabling_cable
        say "Enabling Cable Updates", :green
        append_to_line(
          file: "app/models/team.rb",
          line: "has_many :api_tokens, dependent: :destroy",
          append: ", enable_cable_ready_updates: true"
        )
      end

      def add_patches
        say "Patching model", :green
        conditional_inject(
          file: "app/models/api_token.rb",
          after: "# 🚅 add delegations above.",
          injection: File.read("#{self.source_paths.first}/api_tokens.rb"),
          name: "ApiToken"
        )
      end

      def hide_keys
        say "Hiding keys from the interface", :green

        say "_api_token.html.erb", :blue
        gsub_file "app/views/account/api_tokens/_api_token.html.erb",
          "<td><%= render 'shared/attributes/text', attribute: :access_token, url: [:account, api_token] %></td>",
          "<td><%= access_token_mask(api_token.access_token) %></td>"

        gsub_file "app/views/account/api_tokens/_api_token.html.erb",
          "<% if can? :edit, api_token %>",
          "<% if can?(:edit, api_token) && false %>"

        gsub_file "app/views/account/api_tokens/_api_token.html.erb",
          "<td><%= render 'shared/attributes/option', attribute: :class_name %></td>",
          "<td><%= api_token.class_name %></td>"


          say "_api_token.html.erb - done", :green

        say "api_tokens_controller.rb", :blue
        gsub_file "app/controllers/account/api_tokens_controller.rb",
          %(format.html { redirect_to [:account, @api_token], notice: I18n.t("api_tokens.notifications.created") }),
          %(format.html { redirect_to [:account, @team, :api_tokens], notice: I18n.t("api_tokens.notifications.created") })
        say "api_tokens_controller.rb - done", :green

        say "_form.html.erb", :blue
        gsub_file "app/views/account/api_tokens/_form.html.erb",
          %(<%= render 'shared/fields/super_select', method: :class_name %>),
          %(<%= render 'shared/fields/super_select', method: :class_name, choices: LlmApi.registered_subclasses %>)
        say "_form.html.erb - done", :green
      end
    end
  end
end
