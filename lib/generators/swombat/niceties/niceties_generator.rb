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
    end
  end
end
