# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module UniqNamed
  extend ActiveSupport::Concern

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

=begin

generate uniq name (will check name of model and generates _1 sequenze)

Used as before_update callback, no own use needed

  name = Model.generate_uniq_name('some name')

returns

  result = 'some name_X'

=end

    def generate_uniq_name(name)
      return name if !exists?(name: name)
      (1..100).each { |counter|
        name = "#{name}_#{counter}"
        break if !exists?(name: name)
      }
      name
    end
  end
end
