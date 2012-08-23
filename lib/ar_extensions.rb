module MyActiveRecordExtensions
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # add your static(class) methods here
    def find_by_regexp(column,regexp)
      if ActiveRecord::Base.connection.adapter_name == 'MySQL'
        where(["#{column} REGEXP ?",regexp])
      elsif ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
        where(["#{column} ~* ?", regexp])
     end
    end
  end
end

# include the extension 
ActiveRecord::Base.send(:include, MyActiveRecordExtensions)