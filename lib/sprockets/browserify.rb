require 'sprockets'
require 'tilt'
require 'pathname'
require 'shellwords'

module Sprockets
  # Postprocessor that runs the computed source of Javascript files
  # through browserify, resulting in a self-contained files including all
  # referenced modules
  class Browserify < Tilt::Template

    def prepare
    end

    def evaluate(scope, locals, &block)

      @browserify = false

      File.open(scope.pathname, &:readline).scan(/sprockets.*browserify:\s*(false|true)/) do |groups|
        @browserify = groups[0] == 'true'
      end

      if (File.exist? "#{scope.environment.root}/package.json") && @browserify
        deps = `#{browserify_executable} --list #{scope.pathname}`
        raise "Error finding dependencies" unless $?.success?

        deps.lines.drop(1).each{|path| scope.depend_on path.strip}

        @output ||= `#{browserify_executable} #{browserify_options} #{scope.pathname}`
        raise "Error compiling dependencies" unless $?.success?
        @output
      else
        data
      end
    end

  protected

    def gem_dir
      @gem_dir ||= Pathname.new(__FILE__).dirname + '../..'
    end

    def browserify_executable
      @browserify_executable ||= gem_dir + 'node_modules/browserify/bin/cmd.js'
    end

    def browserify_options
      options = ['-d']

      if ENV['RAILS_ENV'] != 'development'
        options.push('-t uglifyify')
      end

      options.join(' ')
    end

  end
end
