module CustomersHelper

  def redirect_url( customer )
    url = ""
    if(customer.role_id == 1 && customer.dealer_infos.empty?) 
      url = new_dealer_info_url 
    elsif(customer.role_id == 1 && customer.dealers.present?)
      url = edit_dealer_info_url(customer.id)
    elsif(customer.id == 2) 
      url = root_url
    end
    url
  end

end
