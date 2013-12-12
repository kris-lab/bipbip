module Bipbip

  class Storage

    attr_accessor :name
    attr_accessor :config

    def self.factory(name, config)
      require "bipbip/storage/#{Bipbip::Helper.name_to_filename(name)}"
      Storage::const_get(Bipbip::Helper.name_to_classname(name)).new(name, config)
    end

    def initialize(name, config)
      @name = name.to_s
      @config = config.to_h
    end

    def setup_plugin
      raise 'Missing method setup_plugin'
    end

  end
end
