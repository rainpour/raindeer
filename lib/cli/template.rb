# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'ruby-progressbar'

module Rain
  module CLI
    module Template
      extend self

      URL = 'https://github.com/raindeer-rb/raindeer-template'

      def generate(app_name:)
        clone(app_name:)

        # Remove git history.
        FileUtils.rm_rf(File.join(app_name, '.git'))
        system('git', 'init', '--quiet', app_name, exception: true)

        puts "Created #{app_name}, now run: cd #{app_name} && bundle install && rain server"
      end

      # Git reports progress as "Receiving objects:  45% (274/608)" lines separated by carriage returns.
      def clone_progress(line)
        line[/Receiving objects:\s+(\d+)%/, 1]&.to_i
      end

      private

      def clone(app_name:)
        progress_bar = ProgressBar.create(
          total: 100,
          format: "\e[0;34m%a |%B| %p%%\e[0m"
        )
        output = +''

        Open3.popen3('git', 'clone', '--depth', '1', '--progress', URL, app_name) do |_stdin, _stdout, stderr, thread|
          stderr.each_line("\r") do |line|
            output << line
            percent = clone_progress(line)
            # Git repeats "100%" in its final "done" line, and each update to a finished bar prints it again.
            progress_bar.progress = percent if percent && percent > progress_bar.progress
          end

          unless thread.value.success?
            progress_bar.stop
            abort "Couldn't clone #{URL}:\n#{output.tr("\r", "\n")}"
          end
        end

        progress_bar.finish
      end
    end
  end
end
