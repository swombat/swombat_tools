require 'generator_helper'

module Swombat
  module Generators
    class DaisyUiGenerator < Rails::Generators::Base
      include GeneratorHelper

      desc "Installs DaisyUI and configures BulletTrain to use DaisyUI"

      source_root File.expand_path('templates', __dir__)

      class_option :package_manager, type: :string, default: 'yarn', desc: 'Choose the package manager to use: npm or yarn'

      def report_parameters
        say "Preparing to install DaisyUI with options:", :green
        say " - Package manager: #{options[:package_manager]}", :green

        @tailwind_config = tailwind_file
        if File.exist?("config/initializers/bullet_train.rb")
          unless yes?("DaisyUI is **NOT** compatible with BulletTrain. Go ahead anyway? (y/N)", :red)
            say "Installation aborted", :red
            exit
          end
        end
      end

      def install_fontawesome
        unless no?("Install DaisyUI package using #{options[:package_manager]}? (Y/n)", :green)
          install_package(manager: options[:package_manager], package: "daisyui@latest", name: "DaisyUI")
        end
        unless no?("Add DaisyUI to tailwind.config.js? (Y/n)", :green)
          if File.read(@tailwind_config).include?("themeConfig")
            say "using themeConfig to add DaisyUI", :yellow
            conditional_inject(
              file: @tailwind_config,
              after: %(// *** Add your own overrides here ***),
              injection: %{\nthemeConfig.plugins.push(require('daisyui'));},
              name: "DaisyUI"
            )
          else
            say "No themeConfig - looking for plugins[]", :yellow
            conditional_inject(
              file: @tailwind_config,
              after: %(plugins: [),
              injection: %{\nrequire('daisyui'),\n},
              name: "DaisyUI"
            )
          end
        end
      end
    end
  end
end
