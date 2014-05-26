require "test_helper"


class SyncCommitsOnPostReceiveTest < ActiveSupport::TestCase
  include RR::Adapters::TestUnit
  
  context "When GitHub posts to /projects/:slug/hooks/post_receive, Houston" do
    should "sync commits for that project" do
      project = Project.create!(name: "Test", slug: "test", version_control_name: "Mock")
      mock(project.commits).sync!
      Houston.observer.fire "hooks:post_receive", project, {}
    end
  end
  
end
