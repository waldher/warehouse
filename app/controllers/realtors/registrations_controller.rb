class Realtors::RegistrationsController < Devise::RegistrationsController
  def create
    session["#{resource_name}_return_to"] = real_estates_path
    super
  end
end
