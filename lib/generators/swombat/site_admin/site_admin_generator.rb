require 'generator_helper'

module Swombat
  module Generators
    class SiteAdminGenerator < Rails::Generators::Base
      include GeneratorHelper
      desc "Sets up the site admin concept"

      source_root File.expand_path('templates', __dir__)

    end
  end
end
