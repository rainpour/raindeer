# frozen_string_literal: true

module System
  class LayoutNode < LowNode
    def render(event:)
      <html>
        <head>
          <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
          <link rel="stylesheet" href="/system/system.css">
        </head>
        <body>
          <header>
            <div class="container">
              <a id="favicon" href="/system"><img src="/system/favicon.svg"/></a>
              <nav id="navbar">
                <ul>
                  <li><a href="/system">{"Dashboard"}</a>
                  <li><a href="/system/events">{"Events"}</a>
                  <li><a href="/system/requests">{"Requests"}</a>
                  <li><a href="/system/routes">{"Routes"}</a>
                </ul>
              </nav>
            </div>
          </header>

          <main class="container">
            <{ :slot }>
          </main>

          <footer>
            <div class="container">
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
