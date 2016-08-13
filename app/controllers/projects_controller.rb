class ProjectsController < ApplicationController
  before_filter :convert_maintainers_attributes_to_maintainer_ids, only: [:create, :update]
  load_resource :find_by => :slug # will use find_by_permalink!(params[:id])
  authorize_resource


  def index
    @title = "Projects"
    @projects = Project \
      .includes(:head)
      .unretired
    @test_runs = TestRun.most_recent.index_by(&:project_id)
    @releases = Release.where(environment_name: "production").most_recent.index_by(&:project_id)
  end


  def show
    redirect_to projects_path
  end


  def new
    @title = "New Project"

    @project = Project.new
    @project.roles.build(user: current_user) if @project.roles.none?
  end

  def new_from_github
    authorize! :create, Project

    existing_projects = Project.unscoped.where("props->>'git.location' LIKE '%github.com%'")
    github_repos = Houston.benchmark "Fetching repos" do
      Houston.github.repos
    end
    @repos = github_repos.map do |repo|
      project = existing_projects.detect { |project|
        [repo.git_url, repo.ssh_url, repo.clone_url].member?(project.props["git.location"]) }
      { name: repo.name,
        owner: repo.owner.login,
        full_name: repo.full_name,
        private: repo[:private],
        git_location: repo.ssh_url,
        project: project }
    end
  end


  def create_from_github
    authorize! :create, Project

    repos = params.fetch(:repos, [])
    projects = Project.transaction do
      repos.map do |repo|
        owner, name = repo.split("/")
        title = name.humanize.gsub(/\b(?<!['’.`])[a-z]/) { $&.capitalize }.gsub("-", "::")
        Project.create!(
          name: title,
          slug: name,
          version_control_name: "Git",
          props: {"git.location" => "git@github.com:#{repo}.git"})
      end
    end

    flash[:notice] = "#{projects.count} projects added"
    redirect_to projects_path

  rescue ActiveRecord::RecordInvalid
    flash[:error] = $!.message
    redirect_to :back
  end


  def edit
    @project = Project.find_by_slug!(params[:id])
    @project.roles.build(user: current_user) if @project.roles.none?

    @title = "Edit #{@project.name}"
  end


  def create
    @project = Project.new(project_attributes)

    if @project.save
      redirect_to projects_path, notice: 'Project was successfully created.'
    else
      flash.now[:error] = @project.errors[:base].join("\n")
      render action: "new"
    end
  end


  def update
    @project = Project.find_by_slug!(params[:id])

    @project.props.merge! project_attributes.delete(:props) if project_attributes.key?(:props)

    if @project.update_attributes(project_attributes)
      redirect_to projects_path, notice: 'Project was successfully updated.'
    else
      flash.now[:error] = @project.errors[:base].join("\n")
      render action: "edit"
    end
  end


  def retire
    @project = Project.find_by_slug!(params[:id])
    @project.retire!
    redirect_to projects_path, notice: "#{@project.name} was successfully retired."
  end


  def destroy
    @project = Project.find_by_slug!(params[:id])
    @project.destroy

    redirect_to projects_url
  end


private


  def project_attributes
    attrs = params[:project]
    attrs[:selected_features] ||= []
    attrs
  end


  def convert_maintainers_attributes_to_maintainer_ids
    attributes = params.fetch(:project, {}).delete(:maintainers_attributes)
    if attributes
      params[:project][:maintainer_ids] = attributes.values.select { |attributes| attributes[:_destroy] != "1" }.map { |attributes| attributes[:id].to_i }
    end
  end


end
