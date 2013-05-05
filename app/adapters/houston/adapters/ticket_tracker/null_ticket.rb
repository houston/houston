module Houston
  module Adapters
    module TicketTracker
      class NullTicketClass
        
        def remote_id
          nil
        end
        
        def number
          nil
        end
        
        def summary
          nil
        end
        
        def description
          nil
        end
        
        def type
          nil
        end
        
        def tags
          []
        end
        
        def antecedents
          []
        end
        
        def deployment
          nil
        end
        
        def attributes
          {}
        end
        
        def update_attribute(*args)
        end
        
        
        
        def nil?
          true
        end
        
      end
      
      NullTicket = NullTicketClass.new
    end
  end
end
