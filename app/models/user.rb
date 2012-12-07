require 'digest/sha1'
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable,
         :encryptable, :encryptor => :restful_authentication_sha1

  attr_accessible :email, :login, :password, :password_confirmation
    
  belongs_to :project
  has_many :documents, :through => :classifications, :uniq => true
  has_many :classifications
  has_and_belongs_to_many :classifiers, :uniq => true
  
  def fellows
    classifiers.map{|c|c.users.where(['id NOT ?',id])}.flatten.uniq
  end
  
  validates_presence_of :email 
  validates_presence_of :password

  #TODO - Coding statistics by day of week, hour of day, etc.
  def stats
    classifications.size
  end
    
end
