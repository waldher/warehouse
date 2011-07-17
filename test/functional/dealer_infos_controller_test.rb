require 'test_helper'

class DealerInfosControllerTest < ActionController::TestCase
  setup do
    @dealer_info = dealer_infos(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:dealer_infos)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create dealer_info" do
    assert_difference('DealerInfo.count') do
      post :create, :dealer_info => @dealer_info.attributes
    end

    assert_redirected_to dealer_info_path(assigns(:dealer_info))
  end

  test "should show dealer_info" do
    get :show, :id => @dealer_info.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @dealer_info.to_param
    assert_response :success
  end

  test "should update dealer_info" do
    put :update, :id => @dealer_info.to_param, :dealer_info => @dealer_info.attributes
    assert_redirected_to dealer_info_path(assigns(:dealer_info))
  end

  test "should destroy dealer_info" do
    assert_difference('DealerInfo.count', -1) do
      delete :destroy, :id => @dealer_info.to_param
    end

    assert_redirected_to dealer_infos_path
  end
end
