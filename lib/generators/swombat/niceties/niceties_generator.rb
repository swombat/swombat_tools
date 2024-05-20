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
        rm ".rubocop.yml" if File.exist?(".rubocop.yml")
        copy_file "rubocop.yml", ".rubocop.yml"
        say "Rubocop config copied", :green
      end

      def hide_things
        say "Setting HIDE_THINGS to true", :green
        say "Adding HIDE_THINGS=true to config/application.yml", :green
        unless File.read("config/application.yml").include?("HIDE_THINGS=true")
          append_to_file "config/application.yml", "\nHIDE_THINGS=true"
          say "HIDE_THINGS set to true", :green
        else
          say "HIDE_THINGS already set to true, skipping", :yellow
        end
      end

      def add_gems
        say "Adding gems to Gemfile", :green
        append_to_file "Gemfile", "\n" + [%(gem "anthropic", git: "https://github.com/swombat/anthropic"),
          %(gem "ruby-openai"),
          %(gem "ollama-ai")].join("\n")
        say "*** Please run bundle", :green
      end
    end
  end
end
