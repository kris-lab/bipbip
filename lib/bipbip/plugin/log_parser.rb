require 'rb-inotify'

module Bipbip
  class Plugin::LogParser < Plugin
    def metrics_schema
      config['matchers'].map do |matcher|
        { name: matcher['name'], type: 'gauge', unit: 'Boolean' }
      end
    end

    def monitor
      begin
        io = IO.select([notifier.to_io], [], [], 0)
      rescue Errno::EBADF => e
        log(Logger::WARN, 'Selecting from inotify IO gives EBADF, resetting notifier')
        reset_notifier
      end

      unless io.nil?
        n = notifier
        begin
          n.process
        rescue NoMethodError => e
          # Ignore errors from closed notifier - see https://github.com/nex3/rb-inotify/issues/41
          raise e unless n.watchers.empty?
        end
      end

      lines = @lines.entries
      @lines.clear

      Hash[
        config['matchers'].map do |matcher|
          name = matcher['name']
          regexp = Regexp.new(matcher['regexp'])
          value = lines.count { |line| !line.match(regexp).nil? }
          [name, value]
        end
      ]
    end

    private

    def notifier
      if @notifier.nil?
        file_stat = File.stat(config['path'])
        raise "Cannot read file `#{config['path']}`" unless file_stat.readable?
        @lines = []
        @size = file_stat.size
        @notifier = create_notifier
      end
      @notifier
    end

    def create_notifier
      # Including the "attrib" event, because on some systems "unlink" triggers "attrib", but then the inode's deletion doesn't trigger "delete_self"
      events = [:modify, :delete_self, :move_self, :unmount, :attrib]
      notifier = INotify::Notifier.new
      notifier.watch(config['path'], *events) do |event|
        if event.flags.include?(:modify)
          roll_file
        else
          log(Logger::WARN, "File event `#{event.flags.join(',')}` detected, resetting notifier")
          reset_notifier
        end
      end
      notifier
    end

    def reset_notifier
      return if @notifier.nil?
      @notifier.stop
      begin
        @notifier.close
      rescue SystemCallError => e
        log(Logger::WARN, "Cannot close notifier: `#{e.message}`")
      end
      @notifier = nil
    end

    def roll_file
      file = File.new(config['path'], 'r')
      if file.size != @size
        file.seek(@size)
        @lines.push(*file.readlines)
        @size = file.size
      end
      file.close
    end
  end
end
