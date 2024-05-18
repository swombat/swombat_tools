module GeneratorHelper



  private
  def tailwind_file
    say "Checking if Tailwind CSS is installed", :blue
    unless File.exist?('tailwind.config.js') || File.exist?('config/tailwind.config.cjs')
      say "tailwind.config.js not found", :red
      raise Thor::Error, "Tailwind CSS is not installed. Please install Tailwind CSS first." unless testing?
    else
      file = File.exist?('tailwind.config.js') ? "tailwind.config.js" : "config/tailwind.config.js"
      say "Tailwind CSS is installed at #{file}", :green
      file
    end
  end

  def conditional_inject(file:, after:, injection:, name:)
    unless File.exist?(file)
      say "File #{file} does not exist - cannot install #{name}", :red
      return
    end

    contents = File.read(file)
    if contents.include?(injection)
      say "#{name} is already installed in #{file}", :yellow
    else
      if after.nil?
        say "Appending #{name} to #{file}", :blue
        append_to_file file, injection
      elsf contents.include?(after)
        say "Found #{after} in #{file}", :green
        say "Adding #{name} to #{file}", :blue
        inject_into_file file, after: after do
          injection
        end
      else
        say "****************************************************", :red
        say "Couldn't find `#{after}` in #{file}", :red
        say " >>>>> Please add the following line to #{file} manually", :red
        say "```\n#{injection}\n```", :magenta
        say "****************************************************", :red
      end
    end
    say "Finished adding #{name} to #{file}", :green
  end

  def install_package(manager:, package:, name:)
    say "Installing #{name} package with #{manager}", :blue
    run_safe "#{manager} add #{package}"
    say "#{name} package installed with #{manager}", :green
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
