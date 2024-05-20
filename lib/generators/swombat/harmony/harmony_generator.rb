require 'generator_helper'

module Swombat
  module Generators
    class HarmonyGenerator < Rails::Generators::Base
      include GeneratorHelper

      desc "Installs Harmony and configures BulletTrain to use Harmony"

      source_root File.expand_path('templates', __dir__)

      class_option :package_manager, type: :string, default: 'yarn', desc: 'Choose the package manager to use: npm or yarn'

      def report_parameters
        say "Preparing to install Harmony with options:", :green
        say " - Package manager: #{options[:package_manager]}", :green

        @tailwind_config = tailwind_file
        @bullet_train = File.exist?("config/initializers/bullet_train.rb")
      end

      def install_harmony
        unless no?("Install Harmony package using #{options[:package_manager]}? (Y/n)", :green)
          install_package(manager: options[:package_manager], package: "@evilmartians/harmony", name: "Harmony")
          install_package(manager: options[:package_manager], package: "@csstools/postcss-oklab-function", name: "Oklab")
          install_package(manager: options[:package_manager], package: "lodash.merge", name: "LoDash Merge")
        end
        unless no?("Add Harmony to tailwind.config.js? (Y/n)", :green)
          if File.read(@tailwind_config).include?("themeConfig")
            say "using themeConfig to add Harmony", :yellow
            conditional_inject(
              file: @tailwind_config,
              after: %(// *** Add your own overrides here ***),
              injection: [%{\nimport harmonyPalette from "@evilmartians/harmony/tailwind";},
                %{const merge = require('lodash.merge');},
                %[let merged = merge(themeConfig.theme.extend.colors, harmonyPalette, {neutral: harmonyPalette.slate});],
                %(themeConfig.theme.extend.colors = merged;),
                %(themeConfig.plugins.push({'@csstools/postcss-oklab-function': { 'preserve': true }});)
              ].join("\n"),
              name: "Harmony"
            )
          else
            say "No themeConfig - looking for plugins[]", :yellow
            conditional_inject(
              file: @tailwind_config,
              after: %(plugins: [),
              injection: %{\nrequire('harmony'),\n},
              name: "Harmony"
            )
          end
        end
      end
    end
  end
end
