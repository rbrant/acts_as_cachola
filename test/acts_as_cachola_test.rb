require 'test_helper'

class CachedThing < ActiveRecord::Base
  acts_as_cachola
  
  def self.location(options = {}, caps = false)
    rv = 'in the internet'
    if options[:capitalize]
      rv.capitalize!
    end
    
    caps ? rv.upcase : rv
  end
end

class CachedOtherThing < ActiveRecord::Base
  acts_as_cachola_notifier :models => [:cached_thing]
end

class ActsAsCacholaTest < Test::Unit::TestCase
  load_schema

  def setup
    Rails.cache.clear
  end
  
  def test_schema_has_loaded_correctly
    assert_equal [], CachedThing.all
    assert_equal [], CachedOtherThing.all
  end
  
  def test_that_class_responds_to_cached_method_name
    assert_equal CachedThing.location, CachedThing.cachola_location
  end
  
  def test_that_class_doesnt_respond_to_method_names_without_cached
    assert_raises(NoMethodError){CachedThing.x_location}
  end
  
  def test_that_the_method_is_written_to_the_cache
    CachedThing.cachola_location
    assert_equal CachedThing.location, Rails.cache.read('CachedThing.location')
  end
  
  def test_that_the_cache_is_cleared_after_save
    ct = CachedThing.new
    ct.save
    assert_equal nil, Rails.cache.read('CachedThing.location')
  end
  
  def test_that_the_cache_is_cleared_after_destroy
    ct = CachedThing.create
    ct.destroy
    assert_equal nil, Rails.cache.read('CachedThing.location') 
  end
  
  def test_that_the_cache_holds_a_list_of_cached_method_names
    CachedThing.cachola_location
    assert_equal ['CachedThing.location'], Rails.cache.read(CachedThing.cachola_keys_name)
  end

  def test_that_methods_with_diff_signatures_are_stored_seperately
    CachedThing.cachola_location
    CachedThing.cachola_location({:capitalize => true})
    CachedThing.cachola_location({:caps => true}, false)
    
    assert_equal 3, Rails.cache.read(CachedThing.cachola_keys_name).size
  end
  
  def test_that_multiple_args_are_read_properly
    CachedThing.cachola_location({:capitalize => true}, true)
    
    Rails.cache.read(CachedThing.cachola_keys_name).each do |cached_name|
      assert_equal 'IN THE INTERNET', Rails.cache.read(cached_name)
    end 
  end
  
  def test_notifier_clears_cache_of_target_class
    CachedThing.cachola_location
    assert_equal CachedThing.location, Rails.cache.read('CachedThing.location')
    
    cot = CachedOtherThing.create
    cot.destroy
    assert_equal nil, Rails.cache.read('CachedThing.location')
  end
end