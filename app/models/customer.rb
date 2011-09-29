class Customer < ActiveRecord::Base
  has_many :real_estates, :foreign_key => :realtor_id
  has_many :customer_infos
  has_many :latest_infos, :class_name => 'CustomerInfo',:dependent => :delete_all, :conditions => proc {
    last_version = CustomerInfo.where(:customer_id => id).map(&:version).last # find last version of information
    ["version = ?", last_version] if last_version # if new record, 'ver' will be null 
  }

  accepts_nested_attributes_for :latest_infos, :allow_destroy => true, :reject_if => proc { |attr|
    attr['key'].blank? && attr['value'].blank?
  }

  validates :email_address, :format => { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :on => :create }
  validates_uniqueness_of :email_address

  attr_accessor :password
  attr_accessible :email_address, :password, :password_confirmation, :key, :craigslist_type

  validates :password, :confirmation => true, :on => :update

  before_save :increment_version

  before_save :create_hashed_password

  before_save :update_key

  before_create :set_setup_nonce

  AVAILABLE_CRAIGSLIST_TYPES = {
    'Apartments / Housing' => 'apa',
    'Cars & Trucks - By Dealer' => 'ctd'
  }

  def set_setup_nonce
    self.setup_nonce = (0...8).map{97.+(rand(25)).chr}.join
  end

  def update_key
    if self.key_changed? && !self.key.nil?
      self.key = self.key.downcase.gsub(/[^a-z ]/, '').gsub(/  */, '_')
    end
  end

  def increment_version
    last_info = self.customer_infos.last # get last customer_info so we can get version
    new_version = last_info.nil?  ? 1 : last_info.version + 1 # if found increment by 1 else set it to 1
    self.latest_infos.each { |info| info.version = new_version } # set each new info version 
  end

  def maintain_history(attr = {})
    # TODO: have to handle deletion of field
    last_info = self.latest_infos.last # get last history record 
    new_version = last_info.nil? ? 1 : last_info.version + 1 # if have last record increment to new value
    attr.each do |k, v|
      remove_it = v.delete(:_destroy)
      if remove_it == "1"
        self.latest_infos.delete(self.latest_infos.find(v['id']))
        next
      end
      v.delete(:id) if v[:id] # delete id so it is saved as new record instead updating
      v[:version] = new_version # set the new version of record
      self.latest_infos.create(v) 
    end
  end

  def self.authenticate(email, password)
    customer = find_by_email_address(email) 
    customer && customer.match?(password) ? customer : nil
  end

  def create_hashed_password
    unless password.nil? 
      self.setup_nonce = nil
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

  def to_param
    return key
  end
end
