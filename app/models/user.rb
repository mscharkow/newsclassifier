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
  
  def name
    email
  end
  
  def fellows
    classifiers.map{|c|c.users.where(['id NOT ?',id])}.flatten.uniq
  end
  
  validates_presence_of     :email #, :email
  validates_presence_of     :password
#  validates_length_of       :password, :within => 4..40, :if => :password_required?
#  validates_confirmation_of :password,                   :if => :password_required?
#  validates_length_of       :login,    :within => 3..40
#  validates_uniqueness_of   :login, :case_sensitive => false
#  before_save :encrypt_password
    
end
