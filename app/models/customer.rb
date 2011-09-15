class Customer < ActiveRecord::Base
  belongs_to :role
  has_many :real_estates, :foreign_key => :realtor_id
  has_many :dealer_infos, :foreign_key => :dealer_id

  validates :email_address, :format => { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :on => :create }
  validates :email_address, :uniqueness => { :scope => :role_id }

  attr_accessor :password, :name
  attr_accessible :email_address, :password, :name, :password_confirmation

  validates :password, :confirmation => true, :on => :update


  before_save :create_hashed_password
  before_validation :create_key

  scope :dealers, where(:role_id => 1)
  scope :realtors, where(:role_id => 2)

  def create_key
    if key.blank?
      self.key = name.nil? ? " " : name.gsub(/ /, "_").downcase
      unless(key.match(/^([a-z_]+)$/))
        self.errors.add(:base, "Name is invalid. use alphabets")
      end
    end
  end

  def self.authenticate(email, password)
    customer = find_by_email_address(email) 
    customer && customer.match?(password) ? customer : nil
  end

  def create_hashed_password
    unless password.nil? 
      self.salt = Customer.create_salt(email_address) if salt.nil?
      self.hashed_password = Customer.password_with_salt(password, salt)
    end
  end

  def match?(password) 
    self.hashed_password == Customer.password_with_salt(password, salt)
  end

  def self.create_salt(email) 
    Digest::SHA2.hexdigest("Use #{email} with #{Time.now} to create salt")
  end

  def self.password_with_salt(password, salt) 
    Digest::SHA2.hexdigest("Put #{salt} on the #{password}")
  end
end
