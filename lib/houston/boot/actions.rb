require "thread_safe"

module Houston
  class Actions

    def initialize
      @actions = ThreadSafe::Hash.new
    end

    def names
      actions.keys
    end

    def exists?(name)
      actions.key?(name)
    end

    def define(name, &block)
      raise ArgumentError, "#{name.inspect} is already defined" if exists?(name)
      redefine(name, &block)
    end

    def redefine(name, &block)
      raise ArgumentError, "A block is required to define an action" unless block_given?
      actions[name] = block
    end

    def undefine(name)
      raise ArgumentError, "#{name.inspect} is not defined" unless exists?(name)
      actions.delete name
    end

    def run(name, params={}, options={})
      params = ReadonlyHash.new(params.to_h)
      block = actions.fetch(name)
      trigger = options.fetch(:trigger, "manual")
      Houston.async(options.fetch(:async, true)) do
        run! name, params, trigger, block
      end
    end

  private
    attr_reader :actions

    def run!(name, params, trigger, block)
      Action.record name, params, trigger do
        Rails.logger.info "\e[34m[#{trigger} => #{name}] Running job\e[0m"
        params.instance_eval(&block)
      end
    end

  end
end