require 'fileutils'
require 'securerandom'
require 'erb'
require_relative 'version'

module Melodiest

  class Generator
    attr_accessor :destination, :app_name, :app_class_name

    def initialize(app_name, options={})
      @app_name = app_name
      @app_class_name = app_name.split("_").map{|s| s.capitalize }.join("")

      destination = options[:destination] ? "#{options[:destination]}/#{@app_name}" : @app_name
      @with_database = options[:with_database]

      unless File.directory?(destination)
        FileUtils.mkdir_p(destination)
      end

      @destination = File.expand_path(destination)
    end

    def generate_gemfile
      gemfile = File.read File.expand_path("../templates/Gemfile.erb", __FILE__)
      erb = ERB.new gemfile, 0, '-'

      File.open "#{@destination}/Gemfile", "w" do |f|
        f.write erb.result(binding)
      end
    end

    def generate_bundle_config
      config_ru = File.read File.expand_path("../templates/config.ru.erb", __FILE__)
      erb = ERB.new config_ru

      File.open "#{@destination}/config.ru", "w" do |f|
        f.write erb.result(binding)
      end
    end

    # https://github.com/sinatra/sinatra-book/blob/master/book/Organizing_your_application.markdown
    def generate_app
      app = File.read File.expand_path("../templates/app.erb", __FILE__)
      erb = ERB.new app, 0, '-'

      File.open "#{@destination}/#{@app_name}.rb", "w" do |f|
        f.write erb.result(binding)
      end

      FileUtils.mkdir "#{@destination}/public"

      app_dir = "#{@destination}/app"
      ["", "/routes", "/models", "/views"].each do |dir|
        FileUtils.mkdir "#{app_dir}/#{dir}"
      end
    end

    def copy_templates
      FileUtils.cp_r File.expand_path("../templates/assets", __FILE__), @destination
      FileUtils.cp_r File.expand_path("../templates/config", __FILE__), @destination

      if @with_database
        FileUtils.cp File.expand_path("../templates/Rakefile", __FILE__), @destination
        FileUtils.cp_r File.expand_path("../templates/db", __FILE__), @destination
      else
        FileUtils.rm "#{@destination}/config/database.yml.example"
      end
    end
  end

end
