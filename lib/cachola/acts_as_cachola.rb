module Cachola
  
  def self.included(base)
    base.send :extend, ClassMethods
  end

  module ClassMethods
    def acts_as_cachola
      send :include, InstanceMethods

      class_eval <<-CLASS_METHODS
        after_save    :reset_cachola
        after_destroy :reset_cachola
      CLASS_METHODS
    end
    
    def acts_as_cachola_notifier(options={})
      send :include, InstanceMethods
      cattr_accessor :models
      self.models = options[:models]

      class_eval <<-CLASS_METHODS
        after_save    :reset_cachola
        after_destroy :reset_cachola
      CLASS_METHODS
    end

    # key of the name which holds an array of the
    # cached methods for this class
    def cachola_keys_name
      "#{self.to_s.downcase}_cachola_keys"
    end
     
    def method_missing(method_id, *arguments)
      
      if match = /^cachola_.*/.match(method_id.to_s)
     
        actual_method = match[0].gsub(/^cachola_/,'')
        cachola_key   = "#{self.to_s}.#{actual_method}"
        cachola_key   += ".#{arguments.to_s}" unless arguments.empty?
        
        cachola_keys = Rails.cache.read(cachola_keys_name)
        
        # store the name of the class method that was stored if
        # it wasn't called yet
        if cachola_keys.nil?
          Rails.cache.write(cachola_keys_name, [cachola_key])
        else
          
          new_key_list = [[cachola_keys],cachola_key].flatten
          Rails.cache.write(cachola_keys_name, new_key_list) unless cachola_keys.include?(cachola_key)
        end
        
        Rails.cache.fetch(cachola_key){ 
          if arguments.empty?
            self.send(actual_method.to_sym)
          else
            eval "#{self}.send(:#{actual_method}, #{arguments.inspect.gsub(/\[|\]/,'')})"
          end
        }
      else
        super
      end
    end
  end

  module InstanceMethods
    def reset_cachola
      # Can be called from either acts_as_cachola or acts_as_cachola_notifier.
      models = self.class.respond_to?(:models) ? self.models : [self.class]

      # class methods to clear
      models.each do |model|
        Rails.cache.read(model.to_s.classify.constantize.cachola_keys_name).try(:each) do |cached_method|
          Rails.cache.delete( cached_method )
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, Cachola