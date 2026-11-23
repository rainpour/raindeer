# frozen_string_literal: true

# The system pages only have routes with system_mode on, which is while debugging unless it's set otherwise.
if Raindeer.config&.system_mode
  Raindeer.router do
    get '/system' do
      get '/events'
      get '/routes'
    end
  end
end
