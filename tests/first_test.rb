require "minitest/autorun"
require 'configus'

class TestMeme < Minitest::Test

  def test_context
    blk = Proc.new {
      key "value"
      key2 "value2"
    }

    obj = Configus::Context.new({}).build blk
    assert_equal obj[:key][:value], "value"
    assert_equal obj[:key2][:value], "value2"
  end

  def test_group_builder_simple
    env = {:value=>{:key2=>{:value=>"value"}}}
    builder = Configus::GroupBuilder.new env, {}
    conf = builder.build

    assert_equal conf.key2, "value"
  end

  def test_group_builder_with_parent
    parent = {:value=>{:key1=>{:value=>"value_1"}, :key2=>{:value=>"staging_value_2"}}, :params=>{}}
    env = {:value=>{:key2=>{:value=>"value"}}, :params=>{}}

    builder = Configus::GroupBuilder.new env, parent
    conf = builder.build

    assert_equal conf.key2, "value"
    assert_equal conf.key1, "value_1"
  end

  def test_key
    config = Configus.config :staging do
      environment :staging do
        key "value"
      end
    end

    assert_equal(config.key, "value")
  end

  def test_two_keys
    config = Configus.config :staging do
      environment :staging do
        key1 "value1"
        key2 "value2"
      end
    end

    assert_equal(config.key1, "value1")
    assert_equal(config.key2, "value2")
  end

  def test_group
    config = Configus.config :staging do
      environment :staging do
        group do
          key "value"
        end
      end
    end

    assert_equal(config.group.key, "value")
  end

  def test_sub_group
    config = Configus.config :staging do
      environment :staging do
        group do
          subgroup do
            key "value"
          end
        end
      end
    end

    assert_equal(config.group.subgroup.key, "value")
  end

  def test_second_env
    config = Configus.config :production do
      environment :staging do
        key "staging_value"
      end

      environment :production do
        key "production_value"
      end
    end

    assert_equal(config.key, "production_value")
  end

  def test_parent_environment
    config = Configus.config :production do
      environment :staging do
        key1 "value_1"
        key2 "staging_value_2"
      end

      environment :production, parent: :staging do
        key2 "production_value"
      end
    end

    assert_equal(config.key1, "value_1")
    assert_equal(config.key2, "production_value")
  end

  def test_parent_environment_hard
    config = Configus.config :production do
      environment :staging do
        group do
          key1 "value_1"
          key2 "value_2"
        end

        key2 "staging_value_2"
      end

      environment :production, parent: :staging do
        group do
          key1 "production_value"
        end

        key2 "production_value"
      end
    end

    assert_equal(config.group.key1, "production_value")
    assert_equal(config.group.key2, "value_2")
  end
end
