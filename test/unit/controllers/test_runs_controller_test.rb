require "test_helper"


class TestRunsControllerTest < ActionController::TestCase
  
  setup do
    @project = create(:project, ci_server_name: "Mock")
    @test_run = @project.test_runs.create!(sha: "whatever")
    @environment = "production"
  end
  
  
  test "GET #retry should retry the test run" do
    mock.instance_of(TestRun).retry!
    get :retry, {slug: @project.slug, commit: @test_run.sha}
    assert_redirected_to "/test"
  end
  
  
end
