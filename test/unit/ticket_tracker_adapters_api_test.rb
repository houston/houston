require 'test_helper'
require 'support/houston/adapters/ticket_tracker/mock_adapter'

class TicketTrackerAdatersApiTest < ActiveSupport::TestCase
  
  test "Houston::Adapters::TicketTracker.adapters finds all available adapters" do
    assert_equal %w{None Github Mock Unfuddle}, Houston::Adapters::TicketTracker.adapters
  end
  
  connections = []
  Houston::Adapters::TicketTracker.adapters.each do |adapter_name|
    adapter = Houston::Adapters::TicketTracker.adapter(adapter_name)
    connections << adapter.build(Project.new, 1)
    
    test "#{adapter.name} responds to the TicketTracker::Adapter interface" do
      assert_respond_to adapter, :errors_with_parameters
      assert_respond_to adapter, :build
      assert_respond_to adapter, :parameters
    end
  end
  
  tickets = []
  connections.uniq.each do |connection|
    tickets << connection.build_ticket({})
    
    test "#{connection.class.name} responds to the TicketTracker::Connection interface" do
      assert_respond_to connection, :build_ticket
      assert_respond_to connection, :find_ticket
      assert_respond_to connection, :find_tickets!
      
      assert_respond_to connection, :project_url
      assert_respond_to connection, :ticket_url
    end
  end
  
  tickets.uniq.each do |ticket|
    test "#{ticket.class.name} responds to the TicketTracker::Ticket interface" do
      assert_respond_to ticket, :remote_id
      assert_respond_to ticket, :number
      assert_respond_to ticket, :summary
      assert_respond_to ticket, :description
      assert_respond_to ticket, :tags
      assert_respond_to ticket, :antecedents
      
      assert_respond_to ticket, :deployment
      assert_respond_to ticket, :update_attribute
    end
  end
  
end
