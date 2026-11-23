# frozen_string_literal: true

module System
  class LayoutNode < LowNode
    # A page in the system navigation, marked as the current one while it's open.
    Link = Data.define(:path, :label, :current)

    PAGES = { '/system' => 'Dashboard', '/system/requests' => 'Requests', '/system/events' => 'Events',
              '/system/routes' => 'Routes' }.freeze

    # The version goes in the links to the system files, so a browser or a cache like Cloudflare fetches them fresh
    # after each release.
    def initialize(event:)
      @version = Raindeer::VERSION
      path = event.request&.path if event.respond_to?(:request)
      @links = PAGES.map { |page, label| Link.new(path: page, label:, current: (page == path).to_s) }
    end

    def render(event:)
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>{"Raindeer System"}</title>
          <link rel="icon" href="/system/favicon.svg?v={@version}">
          <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
          <link rel="stylesheet" href="/system/system.css?v={@version}">
          <script src="/system/system.js?v={@version}" defer></script>
        </head>
        <body>
          <header class="system-header">
            <div class="container">
              <a class="brand" href="/">
                <img src="/system/logo.png?v={@version}" alt="" width="37" height="48">
                <span>{"Raindeer"}<small>{"System"}</small></span>
              </a>
              <nav>
                <ul>
                  <{ for: link in: @links }>
                    <li><a href="{link.path}" aria-current="{link.current}">{link.label}</a></li>
                  <{ :for }>
                </ul>
              </nav>
            </div>
          </header>

          <main class="container">
            <{ :slot }>
          </main>

          <footer class="system-footer">
            <div class="container">
              <small>{"Raindeer "}{@version}</small>
              <ul>
                <li><a href="https://raindeer.dev">{"Website"}</a></li>
                <li><a href="https://raindeer.dev/docs">{"Docs"}</a></li>
                <li><a href="https://github.com/raindeer-rb/raindeer">{"Source code"}</a></li>
              </ul>
            </div>
          </footer>
        </body>
      </html>
    end
  end
end
