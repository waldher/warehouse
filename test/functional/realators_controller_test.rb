require 'test_helper'

class RealatorsControllerTest < ActionController::TestCase
  setup do
    @realator = realators(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:realators)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create realator" do
    assert_difference('Realator.count') do
      post :create, :realator => @realator.attributes
    end

    assert_redirected_to realator_path(assigns(:realator))
  end

  test "should show realator" do
    get :show, :id => @realator.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @realator.to_param
    assert_response :success
  end

  test "should update realator" do
    put :update, :id => @realator.to_param, :realator => @realator.attributes
    assert_redirected_to realator_path(assigns(:realator))
  end

  test "should destroy realator" do
    assert_difference('Realator.count', -1) do
      delete :destroy, :id => @realator.to_param
    end

    assert_redirected_to realators_path
  end
end
