require "unfuddle"

Unfuddle.config(Houston.config.ticket_tracker_configuration(:unfuddle).merge(
  logger: Rails.logger,
  include_associations: true,
  include_closed_on: true ))
