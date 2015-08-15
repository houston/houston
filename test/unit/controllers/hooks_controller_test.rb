require "test_helper"

class HooksControllerTest < ActionController::TestCase


  context "When GitHub posts a ping event, it" do
    setup do
      request.headers["X-Github-Event"] = "ping"
    end

    should "respond with success" do
      post :github
      assert_response :success
    end
  end


  context "When GitHub posts a pull_request event, it" do
    setup do
      request.headers["X-Github-Event"] = "pull_request"
    end

    should "process it with Github::PullRequestEvent" do
      mock.instance_of(Github::PullRequestEvent).process!
      post :github
    end

    should "respond with success" do
      stub.instance_of(Github::PullRequestEvent).process!
      post :github
      assert_response :success
    end
  end


  context "When GitHub posts a push event, it" do
    setup do
      request.headers["X-Github-Event"] = "push"
    end

    should "process it with Github::PostReceiveEvent" do
      mock.instance_of(Github::PostReceiveEvent).process!
      post :github
    end

    should "respond with success" do
      stub.instance_of(Github::PostReceiveEvent).process!
      post :github
      assert_response :success
    end
  end


  context "When GitHub posts some other event, it" do
    setup do
      request.headers["X-Github-Event"] = "gollum"
    end

    should "respond with not_found" do
      post :github
      assert_response :not_found
    end
  end


end
