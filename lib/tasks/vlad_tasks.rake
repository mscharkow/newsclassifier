begin
  require 'vlad'
  Vlad.load :scm => :git, :app => :unicorn
rescue
 # do nothing
end