require 'generator_helper'

module Swombat
  module Generators
    class InvitationKeysGenerator < Rails::Generators::Base
      include GeneratorHelper

      desc "Sets up an InvitationKeys system that makes sense"

      source_root File.expand_path('templates', __dir__)

      class_option :package_manager, type: :string, default: 'yarn', desc: 'Choose the package manager to use: npm or yarn'

      def report_parameters
        say "Preparing to install Fontawesome with options:", :green
        say " - Package manager: #{options[:package_manager]}", :green
      end

      def install_fontawesome
        unless no?("Install FontAwesome package using #{options[:package_manager]}? (Y/n)", :green)
          install_package(manager: options[:package_manager], package: "@fortawesome/fontawesome-free", name: "FontAwesome")
        end
        unless no?("Add FontAwesome to the application.js? (Y/n)", :green)
          conditional_inject(
            file: "app/javascript/application.js",
            after: %(require("@icon/themify-icons/themify-icons.css")),
            injection: %(\nimport "@fortawesome/fontawesome-free/js/all";\n),
            name: "FontAwesome"
          )
        end
      end
    end
  end
end
