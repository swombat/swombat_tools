module Swombat
  module Generators
    class InstallFlowbiteGenerator < Rails::Generators::Base
      desc "Installs Flowbite and configures Tailwind CSS to use Flowbite"

      source_root File.expand_path('templates', __dir__)

      class_option :bundler, type: :string, default: 'esbuild', desc: 'Choose the bundler to use: importmaps or esbuild'
      class_option :turbo, type: :boolean, default: true, desc: 'Include Turbo support'
      class_option :package_manager, type: :string, default: 'npm', desc: 'Choose the package manager to use: npm or yarn'

      def report_parameters
        say "Preparing to install NiceBite dependencies with options:", :green
        say " - Package manager: #{options[:package_manager]}", :green
        say " - Bundler: #{options[:bundler]}", :green
        say " - Turbo: #{options[:turbo]}", :green
      end

      def check_tailwind_installed
        say "Checking if Tailwind CSS is installed", :blue
        unless File.exist?('tailwind.config.js') || File.exist?('config/tailwind.config.cjs')
          say "tailwind.config.js not found", :red
          raise Thor::Error, "Tailwind CSS is not installed. Please install Tailwind CSS first." unless testing?
        else
          @tailwind_config = "tailwind.config.js" if File.exist?('tailwind.config.js')
          @tailwind_config = "config/tailwind.config.cjs" if File.exist?('config/tailwind.config.js')
          say "Tailwind CSS is installed at #{@tailwind_config}", :green
        end
      end

      def install_flowbite
        unless no?("Install Flowbite package using #{options[:package_manager]}? (Y/n)", :green)
          install_flowbite_package
        end
        unless no?("Attempt to add Flowbite to the tailwind.config.js automatically? (Y/n)", :green)
          configure_tailwind_config
        end
        if options[:turbo]
          unless no?("Attempt to add flowbite turbo support with #{options[:bundler]}? (Y/n)", :green)
            case options[:bundler]
            when "esbuild"
              setup_turbo_esbuild
            when "importmap"
              setup_turbo_importmaps
            else
              say "#{options[:bundler]} is not a supported bundler - please use esbuild or importmap", :red
              raise Thor::Error, "Unsupported bundler option - #{options[:bundler]}"
            end
          end
        else
          say "Skipping Turbo setup", :yellow
        end
      end

      private
      def install_flowbite_package
        say "Installing Flowbite package", :blue
        run_safe "#{options[:package_manager]} install flowbite"
        # run "#{options[:package_manager]} install flowbite"
        say "Flowbite package installed", :green
      end

      def configure_tailwind_config
        say "Attempting to add Flowbite to the tailwind.config.js automatically", :blue
        @tailwind_config_file = File.read(@tailwind_config)
        if @tailwind_config_file.include?("flowbite")
          say "Flowbite seems to already be installed in the tailwind.config.js", :yellow
        else
          if @tailwind_config_file.include?("plugins: [")
            say "Found `plugins: [`", :green
            inject_into_file @tailwind_config, after: "plugins: [" do
              "\n    require('flowbite/plugin'),"
            end
          else
            say "****************************************************", :red
            say "Couldn't find `plugins: [` in the tailwind.config.js", :red
            say " >> Please add `plugins: [require('flowbite/plugin')]` to the tailwind.config.js manually", :red
            say " see https://flowbite.com/docs/getting-started/rails/ for more", :red
            say "****************************************************", :red
          end
          if @tailwind_config_file.include?("content: [")
            say "Found `content: [`", :green
            inject_into_file @tailwind_config, after: "content: [" do
              "\n    './node_modules/flowbite/**/*.js',"
            end
          else
            say "****************************************************", :red
            say "Couldn't find `content: [` in the tailwind.config.js", :red
            say " >> Please add `content: ['./node_modules/flowbite/**/*.js']` to the tailwind.config.js manually", :red
            say " see https://flowbite.com/docs/getting-started/rails/ for more", :red
            say "****************************************************", :red
          end
          say "Finished adding Flowbite to the tailwind.config.js", :green
        end
        say "Flowbite is (probably) in the tailwind.config.js now", :green
      end

      def setup_turbo_importmaps
        @importmaprb_flowbite = %(pin "flowbite", to: "https://cdnjs.cloudflare.com/ajax/libs/flowbite/2.3.0/flowbite.turbo.min.js"
pin "flowbite-datepicker", to: "https://cdnjs.cloudflare.com/ajax/libs/flowbite/2.3.0/datepicker.turbo.min.js"\n)
        @applicationjs_flowbite = "import 'flowbite';\n"
        @importmaprb_file = "config/importmap.rb"
        @applicationjs_file = "app/javascript/application.js"
        if File.exist?(@importmaprb_file)
          append_to_file @importmaprb_file, "\n#{@importmaprb_flowbite}"
        else
          say "****************************************************", :red
          say "Couldn't find config/importmap.rb", :red
          say " >>>>> Please add the following line to importmap.rb manually", :red
          say "```\n#{@importmaprb_flowbite}\n```", :red
          say "see https://flowbite.com/docs/getting-started/rails/ for more", :red
          say "****************************************************", :red
        end
        if File.exist?(@applicationjs_file)
          append_to_file @applicationjs_file, "\n#{@applicationjs_flowbite}"
        else
          say "****************************************************", :red
          say "Couldn't find app/javascript/application.js", :red
          say " >>>>> Please add the following line to application.js manually", :red
          say "```\n#{@applicationjs_flowbite}\n```", :red
          say "see https://flowbite.com/docs/getting-started/rails/ for more", :red
          say "****************************************************", :red
        end
      end

      def setup_turbo_esbuild
        @applicationjs_flowbite = %(import "flowbite/dist/flowbite.turbo.js";
import 'flowbite-datepicker';
import 'flowbite/dist/datepicker.turbo.js';\n)
        @applicationjs_file = "app/javascript/application.js"
        if File.exist?(@applicationjs_file)
          append_to_file @applicationjs_file, "\n#{@applicationjs_flowbite}"
        else
          say "****************************************************", :red
          say "Couldn't find app/javascript/application.js", :red
          say " >>>>> Please add the following line to application.js manually", :red
          say "```\n#{@applicationjs_flowbite}\n```", :red
          say "see https://flowbite.com/docs/getting-started/rails/ for more", :red
          say "****************************************************", :red
        end
      end

      def run_safe(command)
        if testing?
          say "Skipping command: #{command}", :yellow
        else
          run command
        end
      end

      def testing?
        @testing = !ENV["TEST"].nil?
      end
    end
  end
end
