class Realtors::RegistrationsController < Devise::RegistrationsController
  def create
    super
    redirect_to real_estates_path
  end
end
