require 'test_helper'

class HolderTest < ActiveSupport::TestCase
  setup do
    @holder = Holder.first
    @user = User.first
    @competition = Competition.first
  end

  test 'associations' do
    assert @holder.user == @user
    assert @holder.competition == @competition
  end

  test 'enums' do
    assert Holder.team_statuses.is_a? Hash
  end
end
