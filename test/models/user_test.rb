require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    @user = User.find(1)
    @assignment = Assignment.find(1)
  end

  test 'user associations' do
    assert(@user.assignments.include?(@assignment))
    # Dependent Destroy
    id = @user.id
    @user.destroy
    assert(Assignment.where(user_id: id).empty?)
  end

  test 'admin_privileges' do
    # Does have.
    assert(@user.admin_privileges?)
    # Does not have.
    @assignment.destroy
    assert_not(@user.admin_privileges?)
  end
end
