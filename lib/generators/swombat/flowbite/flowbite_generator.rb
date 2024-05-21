require 'generator_helper'

module Swombat
  module Generators
    class FlowbiteGenerator < Rails::Generators::Base
      include GeneratorHelper

      desc "Installs Flowbite and configures Tailwind CSS to use Flowbite"

      source_root File.expand_path('templates', __dir__)

      class_option :bundler, type: :string, default: 'esbuild', desc: 'Choose the bundler to use: importmaps or esbuild'
      class_option :turbo, type: :boolean, default: true, desc: 'Include Turbo support'
      class_option :package_manager, type: :string, default: 'npm', desc: 'Choose the package manager to use: npm or yarn'

      def report_parameters
        say "Preparing to install Flowbite with options:", :green
        say " - Package manager: #{options[:package_manager]}", :green
        say " - Bundler: #{options[:bundler]}", :green
        say " - Turbo: #{options[:turbo]}", :green

        @tailwind_config = tailwind_file
      end

      def install_flowbite
        unless no?("Install Flowbite package using #{options[:package_manager]}? (Y/n)", :green)
          install_package(manager: options[:package_manager], package: "flowbite", name: "Flowbite")
          install_package(manager: options[:package_manager], package: "flowbite-datepicker", name: "Flowbite Datepicker")
        end
        unless no?("Attempt to add Flowbite to the tailwind.config.js automatically? (Y/n)", :green)
          if File.read(@tailwind_config).include?("themeConfig")
            say "using themeConfig to add Flowbite", :yellow
            conditional_inject(
              file: @tailwind_config,
              after: %(// *** Add your own overrides here ***),
              injection: [%{\nthemeConfig.plugins.push(require('flowbite/plugin'));},
                %{themeConfig.content.push('./node_modules/flowbite/**/*.js')}].join("\n"),
              name: "Flowbite"
            )
          else
            say "No themeConfig - looking for plugins[]", :yellow
            conditional_inject(
              file: @tailwind_config,
              after: %(plugins: [),
              injection: %{\n    require('flowbite/plugin'),},
              name: "Flowbite"
            )
            conditional_inject(
              file: @tailwind_config,
              after: %(content: [),
              injection: %{\n    './node_modules/flowbite/**/*.js',},
              name: "Flowbite"
            )
          end
        end
        if options[:turbo]
          unless no?("Attempt to add flowbite turbo support with #{options[:bundler]}? (Y/n)", :green)
            case options[:bundler]
            when "esbuild"
              conditional_inject(
                file: "app/javascript/application.js",
                injection: [%(\nimport "flowbite/dist/flowbite.turbo.js"),
                  %(import 'flowbite-datepicker'),
                  %(import 'flowbite/dist/datepicker.turbo.js')].join("\n"),
                name: "Flowbite"
              )
            when "importmap"
              conditional_inject(
                file: "config/importmap.rb",
                injection: [%(\npin "flowbite", to: "https://cdnjs.cloudflare.com/ajax/libs/flowbite/2.3.0/flowbite.turbo.min.js"),
                  %(pin "flowbite-datepicker", to: "https://cdnjs.cloudflare.com/ajax/libs/flowbite/2.3.0/datepicker.turbo.min.js")].join("\n"),
                name: "Flowbite"
              )
              conditional_inject(
                file: "app/javascript/application.js",
                injection: %(\nimport 'flowbite';\n),
                name: "Flowbite"
              )
            else
              say "#{options[:bundler]} is not a supported bundler - please use esbuild or importmap", :red
              raise Thor::Error, "Unsupported bundler option - #{options[:bundler]}"
            end
          end
        else
          say "Skipping turbo setup", :yellow
        end
      end
    end
  end
end
