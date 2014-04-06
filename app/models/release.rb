class Release < ActiveRecord::Base
  
  after_create :load_commits!, :if => :can_read_commits?
  after_create :release_each_ticket
  after_create { Houston.observer.fire "release:create", self }
  
  belongs_to :project
  belongs_to :user
  belongs_to :deploy
  has_many :changes, :dependent => :destroy
  has_and_belongs_to_many :commits
  has_and_belongs_to_many :tickets, autosave: false # <-- a bug with autosave causes ticket_ids to be saved twice
  
  default_scope { order("created_at DESC") }
  
  accepts_nested_attributes_for :changes, :allow_destroy => true
  
  delegate :maintainers, :to => :project
  
  validates_presence_of :user_id
  validates_uniqueness_of :deploy_id, :allow_nil => true
  validates_associated :changes
  before_validation :ensure_changes_are_associated_with_project
  
  
  
  def self.to_environment(environment_name)
    where(environment_name: environment_name)
  end
  
  def self.for_projects(*projects)
    ids = projects.flatten.map { |project| project.is_a?(Project) ? project.id : project }
    where(project_id: ids)
  end
  
  def self.for_deploy(deploy)
    where(deploy_id: deploy.id)
  end
  
  def self.most_recent_commit
    (release = first) && release.commit1
  end
  
  def self.before(time)
    return all if time.nil?
    where(arel_table[:created_at].lt(time))
  end
  
  def self.latest
    first
  end
  
  def self.earliest
    last
  end
  
  def self.with_message
    where arel_table[:message].not_eq("")
  end
  
  def self.most_recent
    joins <<-SQL
      INNER JOIN (
        SELECT project_id, environment_name, MAX(created_at) AS created_at
        FROM releases
        GROUP BY project_id, environment_name
      ) AS most_recent_releases
      ON releases.project_id=most_recent_releases.project_id
      AND releases.environment_name=most_recent_releases.environment_name
      AND releases.created_at=most_recent_releases.created_at
    SQL
  end
  
  
  
  def can_read_commits?
    valid_sha?(commit0) && valid_sha?(commit1)
  end
  
  def valid_sha?(sha)
    sha.present?
  end
  
  attr_reader :commit_not_found_error_message
  
  
  
  def released_at
    deploy ? deploy.created_at : created_at
  end
  
  def release_date
    released_at.to_date
  end
  alias :date :release_date
  
  
  
  def name
    release_date.strftime("%A, %b %e, %Y")
  end
  
  def message=(value)
    super value.to_s.strip
  end
  
  
  
  def build_changes_from_commits
    commits.each do |commit|
      changes.build Change.attributes_from_commit(commit).merge(release: self, project: project) unless commit.skip?
    end
  end
  
  def load_commits!
    native_commits.each do |native|
      commit = commits.find_by_sha(native.sha)
      attributes = Commit.attributes_from_native_commit(native).merge(project: project)
      if commit
        commit.update_attributes(attributes)
        commits << commit
      else
        commits.build(attributes)
      end
    end
  end
  
  
  
  def ticket_numbers
    commits.each_with_object([]) { |commit, ticket_numbers|
      ticket_numbers.concat commit.ticket_numbers }
  end
  
  def load_tickets!
    self.tickets = project.find_or_create_tickets_by_number(ticket_numbers).to_a
  end
  
  
  
  def antecedents
    @antecedents ||= tickets.map(&:antecedents).flatten.uniq
  end
  
  
  
  def notification_recipients
    @notification_recipients ||= project.followers.unretired.notified_of_releases_to(environment_name)
  end
  
  
  
private
  
  
  def native_commits
    project.repo.commits_between(commit0, commit1)
  rescue Houston::Adapters::VersionControl::CommitNotFound
    @commit_not_found_error_message = $!.message
    @commit_not_found_error_message << " in the repo \"#{project.repo}\"" if project
    []
  rescue Houston::Adapters::VersionControl::InvalidShaError
    @commit_not_found_error_message = $!.message
    []
  end
  
  
  def ensure_changes_are_associated_with_project
    changes.each do |change|
      change.project = project
    end
  end
  
  
  def release_each_ticket
    tickets.each do |ticket|
      ticket.release!(self)
    end
  end
  
  
end
