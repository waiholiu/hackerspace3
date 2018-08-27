class Team < ApplicationRecord
  has_many :assignments, as: :assignable
  belongs_to :event
  has_one :competition, through: :event
  has_many :projects, dependent: :destroy
  has_many :team_data_sets, dependent: :destroy
  has_many :entries, dependent: :destroy
  has_many :peoples_scorecards, dependent: :destroy
  has_many :challenges, through: :entries
  has_many :favourites, dependent: :destroy

  has_one_attached :thumbnail
  has_one_attached :high_res_image

  def team_leader
    assignment = Assignment.find_by(assignable_type: 'Team', assignable_id: id, title: TEAM_LEADER)
    return if assignment.nil?
    assignment.user
  end

  def assign_leader(user)
    assignments.create(title: TEAM_LEADER, user: user)
  end

  def team_members
    ids = assignments.where(title: TEAM_MEMBER).pluck(:user_id)
    return if ids.empty?
    User.where(id: ids)
  end

  def invitees
    ids = assignments.where(title: INVITEE).pluck(:user_id)
    return if ids.empty?
    User.where(id: ids)
  end

  def current_project
    return Project.find(project_id) unless project_id.nil?
    projects.order(created_at: :desc).first
  end

  def change_event(event)
    update(event: event)
  end

  def name
    current_project.team_name
  end

  def regional_challenges(checkpoint)
    challenge_ids = entries.where(checkpoint: checkpoint).pluck(:challenge_id)
    regional_challenges = []
    national_region_id = Region.root.id
    Challenge.where(id: challenge_ids).each do |challenge|
      next if challenge.region_id == national_region_id
      regional_challenges << challenge
    end
    regional_challenges
  end

  def national_challenges(checkpoint)
    challenge_ids = entries.where(checkpoint: checkpoint).pluck(:challenge_id)
    national_challenges = []
    national_region_id = Region.root.id
    Challenge.where(id: challenge_ids).each do |challenge|
      next unless challenge.region_id == national_region_id
      national_challenges << challenge
    end
    national_challenges
  end

  def time_zone
    event.region.time_zone
  end

  def available_checkpoints?
    competition.available_checkpoints(time_zone).present?
  end

  def self.to_csv(options = {})
    project_columns = %w[team_name source_code_url video_url homepage_url created_at updated_at]
    CSV.generate(options) do |csv|
      csv << project_columns
      all.each do |team|
        csv << team.current_project.attributes.values_at(*project_columns)
      end
    end
  end
end