# frozen_string_literal: true

module System
  # Goes to the slowest request on the requests page, in the list of found or missing that it's in, where it opens. The
  # dashboard's slowest response links here, as which request is slowest changes while the dashboard refreshes.
  class SlowestRequestNode < LowNode
    observe '/system/requests/slowest'

    def render(event:) # rubocop:disable Lint/UnusedMethodArgument
      slowest = RequestLog.new.slowest
      return redirect('/system/requests') unless slowest
      return redirect("/system/requests?show=missing##{slowest.anchor}") if slowest.missing?

      redirect("/system/requests##{slowest.anchor}")
    end
  end
end
