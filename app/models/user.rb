class User < ApplicationRecord
  # Devise options
  devise :database_authenticatable, :registerable, :recoverable, :rememberable,
         :trackable, :validatable, :confirmable, :lockable, :timeoutable,
         :omniauthable

  has_many :holders, dependent: :destroy
  has_many :assignments, dependent: :destroy
  has_many :headers, through: :assignments
  has_many :registrations, through: :assignments

  has_many :event_assignments,
    -> { event_assignments },
    class_name: 'Assignment'

  has_many :joined_team_assignments,
    -> { team_confirmed },
    class_name: 'Assignment'

  has_many :joined_teams,
    through: :joined_team_assignments,
    source: :assignable,
    source_type: 'Team'

  has_many :invited_team_assignments,
    -> { team_invitees },
    class_name: 'Assignment'

  has_many :invited_teams,
    through: :invited_team_assignments,
    source: :assignable,
    source_type: 'Team'

  has_many :judge_assignments,
    -> { judges },
    class_name: 'Assignment'

  has_many :challenges_judging,

  through: :judge_assignments,
    source: :assignable,
    source_type: 'Challenge'

  has_many :leader_assignments,
    -> { team_leaders },
    class_name: 'Assignment'

  has_many :leader_teams,
    through: :leader_assignments,
    source: :assignable,
    source_type: 'Team'

  has_many :winning_entries,
    -> { winners },
    through: :leader_teams,
    source: :entries

  has_many :participating_registrations,
    -> { participating },
    through: :assignments,
    source: :registrations

  has_many :participating_events,
    through: :participating_registrations,
    source: :event

  has_many :participating_competition_events,
    -> { competitions },
    through: :participating_registrations,
    source: :event

  has_many :staff_assignments,
    -> { staff },
    class_name: 'Assignment'

  scope :search, lambda { |term|
    where 'full_name ILIKE ? OR email ILIKE ? OR preferred_name ILIKE ?',
          "%#{term}%", "%#{term}%", "%#{term}%"
  }

  scope :mailing_list, -> { where mailing_list: true }

  enum first_peoples: {
    'No' => 0,
    'Yes, Aboriginal' => 1,
    'Yes, Torres Strait Islander' => 2,
    'Prefer not to say' => 3
  }

  enum disability: {
    'Yes' => 0,
    'No' => 1,
    'Prefer not to say' => 2
  }, _suffix: true

  enum education: {
    'Less that Year 12 or equivalent' => 0,
    'Year 12 or equivalent' => 1,
    'Vocational Qualification' => 2,
    'Associate diploma' => 3,
    'Undergraduate diploma' => 4,
    'Bachelor degree (including honours)' => 5,
    'Postgraduate diploma (includes graduate certificate)' => 6,
    "Master's degree" => 7,
    'Doctorate' => 8,
    'Prefer not to say' => 9
  }, _prefix: true

  enum employment: {
    'Employed, working full time' => 0,
    'Employed, working part time or casual' => 1,
    'Student, studying full time' => 2,
    'Student, studying part time' => 3,
    'Not employed, looking for work' => 4,
    'Not employed, NOT looking for work' => 5,
    'Retired' => 6,
    'Disabled, not able to work' => 7,
    'Prefer not to say' => 8
  }, _prefix: true

  enum region: {
    'Queensland' => 0,
    'New South Wales' => 1,
    'Victoria' => 2,
    'Tasmania' => 3,
    'South Australia' => 4,
    'Western Australia' => 5,
    'Northern Territory' => 6,
    'Australian Capital Territory' => 7,
    'New Zealand' => 8,
    'Outside Australia and New Zealand' => 9
  }

  enum age: {
    'Under 18' => 0,
    '18-24 years old' => 1,
    '25-34 years old' => 2,
    '35-44 years old' => 3,
    '45-54 years old' => 4,
    '55-64 years old' => 5,
    '64-75 years old' => 6,
    '75 years and older' => 7,
    'Prefer not to say' => 8
  }, _prefix: true

  validates :accepted_terms_and_conditions, acceptance: true

  # validates :postcode, format: {
  #   with: /\A\d{4}\z/,
  #   message: 'Only 4 digit postcodes',
  #   allow_nil: true
  # }

  acts_as_taggable_on :skills

  # Gravitar Gem
  include Gravtastic
  has_gravatar

  # Active Storage prifel image.
  has_one_attached :govhack_img

  # ENHANCEMENT: Need validation to make sure email is fully formed.

  # Returns true if a user has any of the privileges (assignments) passed
  # through the parameters.
  # ENHANCEMENT: Move to Controller.
  def privilege?(privileges)
    (privileges & assignments).present?
  end

  # Returns true if a user has any competition admin titles.
  # ENHANCEMENT: Move to Controller.
  # ENHANCEMENT: Check against assignments not titles.
  def admin_privileges?(competition)
    assignments.where(competition: competition, title: COMP_ADMIN).any?
  end

  # Returns true if a user has any region admin titles.
  # ENHANCEMENT: Move to Controller.
  # ENHANCEMENT: Check against assignments not titles.
  def region_privileges?(competition)
    assignments.where(competition: competition, title: REGION_PRIVILEGES).any?
  end

  # Returns true if a user has any event admin titles.
  # ENHANCEMENT: Move to Controller.
  # ENHANCEMENT: Check against assignments not titles.
  def event_privileges?(competition)
    assignments.where(competition: competition, title: EVENT_PRIVILEGES).any?
  end

  # Returns true if a user has any sponsor admin titles.
  # ENHANCEMENT: Move to Controller.
  # ENHANCEMENT: Check against assignments not titles.
  def sponsor_privileges?(competition)
    assignments.where(competition: competition, title: SPONSOR_PRIVILEGES).any?
  end

  # Returns true if a user has any criterion admin titles.
  # ENHANCEMENT: Move to Controller.
  # ENHANCEMENT: Check against assignments not titles.
  def criterion_privileges?(competition)
    assignments.where(competition: competition, title: CRITERION_PRIVILEGES).any?
  end

  # Assigns a user the assignment of site admin.
  def make_site_admin(competition, holder)
    competition.assignments.find_or_create_by user: self, title: ADMIN, holder: holder
  end

  # Returns a display name in order of system preference.
  def display_name
    return preferred_name unless preferred_name.blank?
    return full_name unless full_name.blank?

    email
  end

  # Returns the event assignment of a particular user.
  # This is the assignment to the competition that is used to register for
  # events (among other things), in a given competition.
  def event_assignment(competition)
    holder = holder_for(competition)
    assignment = competition.assignments.find_by user: self, title: VIP, holder: holder
    return assignment unless assignment.nil?

    competition.assignments.find_or_create_by user: self, title: PARTICIPANT, holder: holder
  end

  # Returns a user's event_assignment if they have permission to vote.
  def judgeable_assignment(competition)
    event_assignment competition if
      joined_teams.competition(competition).published.present? ||
      assignments.judgeables.where(competition: competition).present?
  end

  # Returns a user's event_assignment if they have permission to vote in the
  # people's choice awards.
  def peoples_assignment(competition)
    event_assignment competition if
      joined_teams.published.competition(competition).present? ||
      assignments.volunteers.where(competition: competition).present?
  end

  # Returns the competition holder of a particular user. this is the container
  # that holds a user's assignments, scorecards, registrations, and favourites
  def holder_for(competition)
    holders.find_or_create_by competition: competition
  end

  # Returns a user's challenge judging assignment given a challenge.
  def judge_assignment(challenge)
    assignments.judges.find_by assignable: challenge
  end

  # Returns true if a user has no set dietary requirements.
  def no_dietary_requirements?
    dietary_requirements.blank?
  end

  def participating_competition_event(competition)
    participating_competition_events.competition(competition).first
  end

  def site_admin?(competition)
    assignments.where(competition: competition, title: ADMIN).present?
  end

  def confirmed_status
    return 'unconfirmed' if confirmed_at.nil?

    "confirmed at #{confirmed_at.strftime('%e %B %Y  %I.%M %p')}"
  end
end
