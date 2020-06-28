require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    @user = User.first
    @holder = Holder.first
    @assignment = Assignment.first
    @team = Team.first
    @header= Header.second
    @registration = Registration.first
    @joined_team_assignment = Assignment.find 11
    @joined_team = @team
    @invitee = User.third
    @invited_team_assignments = Assignment.find 12
    @invited_team = @team
    @judge = User.second
    @judge_assignment = Assignment.find 7
    @challenge = Challenge.first
    @leader_assignment = @joined_team_assignment
    @winning_entry = Entry.third
    @competition_registration = Registration.third
    @participating_event = Event.first
    @competition_event = Event.second
    @staff_assignment = @assignment
    @participant_assignment = Assignment.fourth
    @competition = Competition.first
    @unconfirmed_user = users(:unconfirmed_user)
  end

  test 'user associations' do
    assert @user.holders.include? @holder
    assert @user.assignments.include? @assignment
    assert @user.headers.include? @header
    assert @user.registrations.include? @registration

    assert @user.event_assignments.include? @participant_assignment

    assert @user.joined_team_assignments.include? @joined_team_assignment
    assert @user.joined_teams.include? @joined_team

    assert @invitee.invited_team_assignments.include? @invited_team_assignments
    assert @invitee.invited_teams.include? @invited_team

    assert @judge.judge_assignments.include? @judge_assignment
    assert @judge.challenges_judging.include? @challenge

    assert @user.leader_assignments.include? @leader_assignment
    assert @user.leader_teams.include? @team
    assert @user.winning_entries.include? @winning_entry

    assert @user.participating_registrations.include? @competition_registration
    assert @user.participating_events.include? @participating_event
    assert @user.participating_competition_events.include? @competition_event

    assert @user.staff_assignments.include? @staff_assignment
    assert @user.staff_assignments.exclude? @participant_assignment

    @user.destroy
    assert_raises(ActiveRecord::RecordNotFound) { @assignment.reload }
  end

  test 'enums' do
    assert User.first_peoples.is_a? Hash
    assert User.disabilities.is_a? Hash
    assert User.educations.is_a? Hash
    assert User.employments.is_a? Hash
    assert User.regions.is_a? Hash
    assert User.ages.is_a? Hash
  end

  test 'scopes' do
    assert User.search('one').include? @user
    assert User.mailing_list.include? @user
    assert User.mailing_list.exclude? @judge
  end

  test 'user validations' do
    # no email don't save
    assert_not User.create(email: nil).save

    # no full name don't save
    assert_not User.create(
      email: 'name@example.com',
      full_name: nil
    ).save

    assert_not User.create(
      email: 'name@example.com',
      full_name: 'Full Name',
      accepted_terms_and_conditions: false
    ).save
  end

  test 'event_assignment' do
    assert @user.event_assignment(@competition) == @participant_assignment
  end

  test 'admin_privileges' do
    assert @user.admin_privileges? @competition
    @assignment.destroy
    assert_not @user.admin_privileges? @competition
  end

  test 'region_privileges' do
    assert @user.region_privileges? @competition
    @user.assignments.destroy_all
    assert_not @user.region_privileges? @competition
  end

  test 'event_privileges' do
    assert @user.event_privileges? @competition
    @user.assignments.destroy_all
    assert_not @user.event_privileges? @competition
  end

  test 'sponsor_privileges' do
    assert @user.sponsor_privileges? @competition
    @user.assignments.destroy_all
    assert_not @user.sponsor_privileges? @competition
  end

  test 'criterion_privileges' do
    assert @user.criterion_privileges? @competition
    @user.assignments.destroy_all
    assert_not @user.criterion_privileges? @competition
  end

  test 'holder_for' do
    assert @user.holder_for(@competition) == @holder
  end

  test 'judgeable_assignment' do
    assert @user.judgeable_assignment(@competition).present?
    assert_not @invitee.judgeable_assignment(@competition).present?
  end

  test 'peoples_assignment' do
    assert @user.peoples_assignment(@competition).present?
    assert_not User.find(3).peoples_assignment(@competition).present?
  end

  test 'judge_assignment' do
    assert @judge.judge_assignment(@challenge) == @judge_assignment
    assert_nil @user.judge_assignment @challenge
  end

  test 'participating_competition_event' do
    assert @user.participating_competition_event(@competition) == @competition_event
  end

  test 'site_admin?' do
    assert_not @user.site_admin? @competition
    @user.assignments.create assignable: @competition, title: ADMIN, holder: @holder
    assert @user.site_admin? @competition
  end

  test 'confirmed_status' do
    assert @unconfirmed_user.confirmed_status == 'unconfirmed'
    @unconfirmed_user.confirm
    assert @unconfirmed_user.confirmed_status.match? 'confirmed at'
  end
end
