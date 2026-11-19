# frozen_string_literal: true

module Rain
  module Events
    # A request's body as a string. It's a stream that can only be read once, so it's buffered on the request for
    # everything that reads it, like the router checking a form's token and then the node it's for.
    module Body
      def self.read(request)
        return '' unless request&.body

        request.body = request.body.finish
        request.body.rewind
        request.body.join || ''
      end
    end
  end
end
