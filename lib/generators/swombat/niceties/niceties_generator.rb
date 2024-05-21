require 'generator_helper'

module Swombat
  module Generators
    class NicetiesGenerator < Rails::Generators::Base
      include GeneratorHelper
      desc "Installs Various nice things (ERD,...)"

      source_root File.expand_path('templates', __dir__)

      def filter_erd
        say "Setting ERD config will make the erd.pdf actually useful", :green
        if File.exist?(".erdconfig")
          say "ERD config exists arleady, skipping ERD setup", :yellow
        else
          say "ERD config not found, creating it", :green
          copy_file "erdconfig", ".erdconfig"
          say "ERD config created", :green
        end
      end

      def copy_rubocop_config
        say "Overwriting rubocop config", :green
        File.delete(".rubocop.yml") if File.exist?(".rubocop.yml")
        copy_file "rubocop.yml", ".rubocop.yml"
        say "Rubocop config copied", :green
      end

      def disable_developer_menu
        say "Setting DISABLE_DEVELOPER_MENU to true", :green
        say "Adding DISABLE_DEVELOPER_MENU=true to config/application.yml", :green
        unless File.read("config/application.yml").include?("DISABLE_DEVELOPER_MENU")
          append_to_file "config/application.yml", "\DISABLE_DEVELOPER_MENU: true"
          say "DISABLE_DEVELOPER_MENU set to true", :green
        else
          say "DISABLE_DEVELOPER_MENU already set to true, skipping", :yellow
        end
      end

      def hide_things
        say "Setting HIDE_THINGS to true", :green
        say "Adding HIDE_THINGS=true to config/application.yml", :green
        unless File.read("config/application.yml").include?("HIDE_THINGS")
          append_to_file "config/application.yml", "\nHIDE_THINGS: true"
          say "HIDE_THINGS set to true", :green
        else
          say "HIDE_THINGS already set to true, skipping", :yellow
        end
      end


      def add_gems
        say "Adding gems to Gemfile", :green
        unless File.read("Gemfile").include?("anthropic")
          append_to_file "Gemfile", "\n" + [%(gem "anthropic", git: "https://github.com/swombat/anthropic"),
            %(gem "ruby-openai"),
            %(gem "ollama-ai")].join("\n")
          say "Appended anthropic, ruby and ollama gems", :green
          say "*** Please run bundle", :green
        else
          say "Anthropic gem already in Gemfile, skipping", :yellow
        end
      end

      def sidekiq
        say "Setting up Sidekiq", :green
        unless File.read("config/initializers/sidekiq.rb").include?("sidekiq_development.log")
          unless no?("Setup alternative queue for Sidekiq? (Y/n)", :green)
            db_number = ask("What is the number of the database you want to use for Sidekiq? (1-16, default: 1)", :green)
            db_number = 1 if db_number.blank?
            say "Appending sidekiq settings", :green
            append_to_file "config/initializers/sidekiq.rb", "\n" + File.read("#{self.source_paths.first}/sidekiq.rb")
            gsub_file "config/initializers/sidekiq.rb", "{{DB}}", db_number.to_s
          else
            say "Sidekiq alternative queue not setup, skipping", :yellow
          end
        else
          say "Sidekiq alternative queue already setup, skipping", :yellow
        end
      end

      def update_dev_procfile
        new_port = ask("Update Procfile to set custom port? (default: 3000)", :green)
        if new_port.present? && new_port != 3000
          say "Updating Procfile", :green
          gsub_file "Procfile.dev", "3000", new_port
        end
      end

      def update_production_procfile
        say "Updating Production Procfile", :green
        gsub_file "Procfile", "-t 5:5", "-t 8:32"
        gsub_file "Procfile", "release: bundle exec rails db:migrate; bundle exec rails db:seed", "release: bundle exec rails db:migrate"
      end

      def copy_dockerfile
        say "Copying Dockerfile", :green
        unless File.exist?("Dockerfile")
          copy_file "Dockerfile", "Dockerfile"
          say "Dockerfile copied", :green
        else
          say "Dockerfile already exists, skipping", :yellow
        end
      end
    end
  end
end
