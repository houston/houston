require 'oauth/controllers/consumer_controller'
class OauthConsumersController < ApplicationController
  include Oauth::Controllers::ConsumerController

  before_filter :authenticate_user!, only: :index

  def index
    @consumer_tokens = ConsumerToken.where(user_id: current_user.id)
    @services = OAUTH_CREDENTIALS.keys - @consumer_tokens.map { |c| c.class.service_name }
  end

  def callback
    super
  end
  
  def callback2
    super
  end

  def client
    super
  end

  # for some reason oauth-plugin is broken and can't figure this out:
  def callback2_oauth_consumer_url
    root_url + "oauth_consumers/github/callback2"
  end


protected

  # Change this to decide where you want to redirect user to after callback is finished.
  # params[:id] holds the service name so you could use this to redirect to various parts
  # of your application depending on what service you're connecting to.
  def go_back
    redirect_to session.fetch("user.return_to", pull_requests_url)
  end

  # The plugin requires logged_in? to return true or false if the user is logged in. Uncomment and
  # call your auth frameworks equivalent below if different. eg. for devise:
  def logged_in?
    user_signed_in?
  end

  # The plugin requires current_user to return the current logged in user. Uncomment and
  # call your auth frameworks equivalent below if different.
  # def current_user
  #   current_person
  # end

  # The plugin requires a way to log a user in. Call your auth frameworks equivalent below
  # if different. eg. for devise:
  def current_user=(user)
    sign_in(user)
  end

  # Override this to deny the user or redirect to a login screen depending on your framework and app
  # if different. eg. for devise:
  def deny_access!
    raise CanCan::AccessDenied
  end

end
