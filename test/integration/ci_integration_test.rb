require "test_helper"
require "support/houston/adapters/ci_server/mock_adapter"


# Tests config/initializers/run_tests_on_post_receive.rb
class CIIntegrationTest < ActionDispatch::IntegrationTest


  context "Houston" do
    should "trigger a build when the hooks:post_receive event is fired for a project that uses a CI server" do
      @project = create(:project, ci_server_name: "Mock")

      stub.instance_of(PostReceivePayload).commit { "63cd1ef" }

      assert_difference "TestRun.count", +1 do
        post "/projects/#{@project.slug}/hooks/post_receive"
        assert_response :success
      end
    end

    should "do nothing when the hooks:post_receive event is fired for a project that does not use a CI server" do
      @project = create(:project, ci_server_name: "None")

      assert_no_difference "TestRun.count" do
        post "/projects/#{@project.slug}/hooks/post_receive"
        assert_response :success
      end
    end

    should "alert maintainers when a build cannot be triggered" do
      @project = create(:project, ci_server_name: "Mock")
      @project.add_teammate users(:boblail), "Maintainer"

      any_instance_of(Houston::Adapters::CIServer::MockAdapter::Job) do |job|
        stub(job).build! { |commit| raise Houston::Adapters::CIServer::Error }
      end

      stub.instance_of(PostReceivePayload).commit { "63cd1ef" }

      assert_no_difference "TestRun.count" do
        post "/projects/#{@project.slug}/hooks/post_receive"
        assert_response :success

        configuration_error = ActionMailer::Base.deliveries.last
        assert_not_nil configuration_error, "No deliveries have been recorded"
        assert_equal "Test: configuration error", configuration_error.subject
      end
    end



    should "fetch results_url when the hooks:post_build event is fired" do
      commit = "whatever"
      results_url = "http://example.com/results"
      @project = create(:project, ci_server_name: "Mock")
      @test_run = TestRun.create!(project: @project, sha: commit)

      any_instance_of(Houston::Adapters::CIServer::MockAdapter::Job) do |job|
        mock(job).fetch_results!(results_url).returns({})
      end

      post "/projects/#{@project.slug}/hooks/post_build", {commit: commit, results_url: results_url}
      assert_response :success
    end

    should "mark the build as \"error\" when a build cannot be processed" do
      commit = "whatever"
      results_url = "http://example.com/results"
      @project = create(:project, ci_server_name: "Mock")
      @project.add_teammate users(:boblail), "Maintainer"
      @test_run = TestRun.create!(project: @project, sha: commit)

      any_instance_of(Houston::Adapters::CIServer::MockAdapter::Job) do |job|
        mock(job).fetch_results!(results_url) { raise Houston::Adapters::CIServer::Error }
      end

      post "/projects/#{@project.slug}/hooks/post_build", {commit: commit, results_url: results_url}

      assert_equal "error", @test_run.reload.result
    end



    should "fire test_run:complete when the results of the test run are saved" do
      @project = create(:project, ci_server_name: "Mock")
      test_run = TestRun.new(project: @project, sha: "whatever")

      any_instance_of(Houston::Adapters::CIServer::MockAdapter::Job) do |job|
        stub(job).fetch_results! { |results_url| {result: "pass"} }
      end

      assert_triggered "test_run:complete" do
        test_run.completed!("http://jenkins.com/results")
      end
    end



    should "publish test status to GitHub when pending" do
      # don't pull changes for this repo
      git = stub(Houston::Adapters::VersionControl::GitAdapter)
      git.sync! { |*args| }
      git.get_local_path_to_repo { |_,_| Rails.root.join("test/data/bare_repo.git").to_s }

      @project = Project.create!(
        name: "Test",
        slug: "fixture",
        version_control_name: "Git",
        extended_attributes: { "git_location" => "git@github.com:houston/fixture.git" })
      test_run = TestRun.new(project: @project, sha: "bd3e9e2")

      expected_url = "https://api.github.com/repos/houston/fixture/statuses/bd3e9e2e4ddf89a640a4f880cbf55bb46cc7e88a?access_token=#{Houston.config.github[:access_token]}"
      mock(Faraday).post(expected_url, /"state":"pending"/) do
        stub(Object.new).success? { true }
      end

      Houston.observer.fire "test_run:start", test_run
    end

    should "publish test results to GitHub" do
      # don't pull changes for this repo
      git = stub(Houston::Adapters::VersionControl::GitAdapter)
      git.sync! { |*args| }
      git.get_local_path_to_repo { |_,_| Rails.root.join("test/data/bare_repo.git").to_s }

      @project = Project.create!(
        name: "Test",
        slug: "fixture",
        version_control_name: "Git",
        extended_attributes: { "git_location" => "git@github.com:houston/fixture.git" })
      test_run = TestRun.new(project: @project, sha: "bd3e9e2", result: :pass, completed_at: Time.now)

      expected_url = "https://api.github.com/repos/houston/fixture/statuses/bd3e9e2e4ddf89a640a4f880cbf55bb46cc7e88a?access_token=#{Houston.config.github[:access_token]}"
      mock(Faraday).post(expected_url, /"state":"success"/) do
        stub(Object.new).success? { true }
      end

      Houston.observer.fire "test_run:complete", test_run
    end



    should "publish test results to CodeClimate" do
      @project = create(:project, code_climate_repo_token: "repo_token")
      test_run = TestRun.new(project: @project, sha: "bd3e9e2", result: "pass", completed_at: Time.now, coverage: [
        { filename: "lib/test1.rb", coverage: [1,nil,nil,1,1,nil,1] },
        { filename: "lib/test2.rb", coverage: [1,nil,1,0,0,0,0,1,nil,1] }
      ])

      mock(CodeClimate::CoverageReport).publish!(test_run)

      Houston.observer.fire "test_run:complete", test_run
    end
  end


end
