require 'generator_helper'

module Swombat
  module Generators
    class InvitationKeysGenerator < Rails::Generators::Base
      include GeneratorHelper

      desc "Sets up an InvitationKeys system that makes sense"

      source_root File.expand_path('templates', __dir__)

      def check_not_installed
        say "Checking that InvitationKeys is not already installed", :green
        if File.exist?("app/models/invitation_key.rb")
          say "It looks like InvitationKeys is already installed. Aborting.", :red
          exit
        end
      end

      def run_generator
        say "Running generator...", :green
        rails_command "generate super_scaffold InvitationKey Team key:text_field"
      end

      def run_migrations
        say "Running migrations...", :green
        unless no?("Run migrations now? (Y/n)", :green)
          rails_command "db:migrate"
        else
          say "Skipping migrations - don't forget to rails db:migrate!", :yellow
        end
      end

      def add_patches
        say "Patching BulletTrain Invitation system", :green
        conditional_inject(
          file: "config/initializers/bullet_train.rb",
          injection: File.read("#{self.source_paths.first}/bullet_train.rb"),
          name: "Upgraded Invitation System"
        )
      end
    end
  end
end
