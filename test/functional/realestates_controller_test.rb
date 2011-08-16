require 'test_helper'

class RealestatesControllerTest < ActionController::TestCase
  setup do
    @realestate = realestates(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:realestates)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create realestate" do
    assert_difference('Realestate.count') do
      post :create, :realestate => @realestate.attributes
    end

    assert_redirected_to realestate_path(assigns(:realestate))
  end

  test "should show realestate" do
    get :show, :id => @realestate.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @realestate.to_param
    assert_response :success
  end

  test "should update realestate" do
    put :update, :id => @realestate.to_param, :realestate => @realestate.attributes
    assert_redirected_to realestate_path(assigns(:realestate))
  end

  test "should destroy realestate" do
    assert_difference('Realestate.count', -1) do
      delete :destroy, :id => @realestate.to_param
    end

    assert_redirected_to realestates_path
  end
end
