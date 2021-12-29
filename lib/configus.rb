require 'pry'

class Configus

  class Group
  end

  class GroupBuilder
    def initialize(environment, parent = {})
      @environment = environment
      @parent = parent
    end

    def build
      value = @environment[:value]
      parent_value = @parent[:value] || {}

      if value.is_a?(Hash)
        @group = Group.new

        parent_value.keys.each do |key|
          if(value[key].nil?)
            builder = GroupBuilder.new(parent_value[key], parent_value[key] || {})
            val = builder.build
            @group.define_singleton_method key do
              val
            end
          end
        end

        value.keys.each do |key|
          builder = GroupBuilder.new(value[key], parent_value[key] || {})
          val = builder.build
          @group.define_singleton_method key do
            val
          end
        end

        return @group
      else
        return value
      end
    end
  end

  class Context
    def initialize(obj)
      @obj = obj
    end

    def build(blk)
      self.instance_eval(&blk)
      @obj
    end

    def method_missing(method_name, *params, &blk)
      if block_given?
        ctx = Context.new({})
        env = ctx.build blk

        @obj[method_name] = {
          value: env
        }
      else
        @obj[method_name] = {
          value: params.first
        }
      end
    end
  end

  class Builder

    def initialize(blk)
      @blk = blk
      @environments = {}
    end

    def self.build(blk)
      instance = new(blk)
      instance.build
      instance
    end

    def build
      self.instance_eval(&@blk)
    end

    def environment(name, params = {}, &blk)
      hash = Context.new({}).build blk

      @environments[name] = {
        value: hash,
        params: params
      }
    end

    def get_environment(name)
      parent_name = @environments[name][:params][:parent]
      parent = {}

      if(!parent_name.nil?)
        parent = @environments[parent_name]
      end

      builder = GroupBuilder.new(@environments[name], parent)
      builder.build
    end
  end

  class << self
    def config(environment_name, &blk)
      Builder.build(blk).get_environment(environment_name)
    end
  end

end
