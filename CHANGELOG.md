# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.0.53

### Added

- Each interval pill on the system dashboard shows how its turn went and refreshes each second. A circle spins while it runs and it's green once it ran and red if it failed and blue if it was skipped. Its tooltip says which

### Changed

- Needs LowLoop 0.8.17

## 1.0.52

### Fixed

- An interval kept to an hour like `every_minute: 3, at_hour: 2` is on the hours dial at its hour rather than on every hour's minutes

## 1.0.51

### Added

- A dial of the days in a week on the system dashboard for intervals of several days

### Changed

- Each interval is on the dial of the largest unit it has several of. So a daily job is on the hours dial at its hour and an every minute job is on the seconds dial at 0

### Fixed

- An interval's tooltip shows past its pill rather than being cut off

## 1.0.50

### Changed

- The system dashboard's trends are always shown under its intervals and end with the current reading. A lone reading is a flat line
- The interval dials are two across

## 1.0.49

### Changed

- The system dashboard shows its intervals on dials of the seconds in a minute and the minutes in an hour and the hours in a day. Each interval is on every mark its turns start on and a neon line steps down each dial with the server's clock
- Needs LowLoop 0.8.16 whose intervals follow the clock

## 1.0.48

### Added

- Rate limits. List paths under `rate_limits` in `config.yaml` with the pages a minute each visitor may ask for there. The most specific path's limit applies, files and the system pages don't count, and a visitor over it gets a 429 with `Retry-After`
- The system dashboard's Denied (24 hours) stat in place of Nodes, linking to the requests page's new Denied list of 429s

### Fixed

- A request from another site shows on the requests page as its 403 rather than still being answered

## 1.0.47

### Changed

- The system dashboard's slowest response links to `/system/requests/slowest`, a page of its own with the slowest request open, and its title stays grey until it's pointed at
- The stat cards have padding under their titles

## 1.0.46

### Added

- The system dashboard's slowest response links to its request on the requests page, which opens it

## 1.0.45

### Changed

- The system dashboard shows actions per second in place of answering now. It counts every event that runs, like requests and node renders and data queries and intervals, including the system pages' own

## 1.0.44

### Added

- Sites. List hosts under `sites` in `config.yaml` with their region and language. Every event made from a request has `event.site` with its host and origin and region, and `event.site.alternates` for `hreflang` links
- `event.locale` with the response's language and the visitor's region. The region is the site's or else the country in Cloudflare's `CF-IPCountry` header

### Changed

- A request without a language there's a translation for is rendered in its site's language, which is the `source_locale` unless the site sets another

## 1.0.43

### Changed

- The system pages' text is 10% smaller than Pico's default so more fits

## 1.0.42

### Changed

- The Requests page's Found and Missing switch sits on the intro's row on the right

## 1.0.41

### Fixed

- A route with a static segment beside a `:param` route, like `/posts/drafts/:id` beside `/posts/:id`, renders rather than responding 404. A static segment that matches a route to the end of the path wins over the `:param`, and the `:param` route's side effects don't run
- Each route event has only the params of its own route. They shared one hash, so `/posts/drafts/7` gave `/posts/drafts/:id` the `id` `drafts`
- Needs Antlers 1.5.9, for its fix to a slot inside another component's slot

## 1.0.40

### Changed

- The Events and Routes pages show each event and observer by its name as code like `RequestEvent` with its namespace in a tooltip
- The Requests page says how many requests it keeps from the event pool's size
- The Events page counts the route event's routes with a link to the Routes page instead of listing every node that observes one
- Needs LowEvent 0.8.9

### Added

- The Requests page switches between Found and Missing requests and shows the page that linked to each one when the browser said

### Fixed

- The Requests page leaves out the request being answered now. Without the rule keeping the system pages apart it rendered its own tree as it added to it forever

## 1.0.39

### Fixed

- The Routes page failed since 1.0.33 as it asked a route's path for its observers. The observers formatter looks up a key that can't answer for itself

### Changed

- The system header hides the deer on a phone

## 1.0.38

### Changed

- A request's bar shows a segment's whole label in Pico's tooltip when hovering a segment too narrow for it
- The system header is only as tall as the deer

## 1.0.37

### Changed

- Each request on the Requests page opens with a bar of where its own time went instead of the dashboard showing an average of every request
- The system header's deer is smaller and a silhouette in white on dark and near black on light

## 1.0.36

### Changed

- The event pool keeps interval ticks apart because they say they're internal so Raindeer's rule only names the system pages
- Needs LowEvent 0.8.8 and LowLoop 0.8.15

## 1.0.35

### Fixed

- The system pages' own requests and interval ticks go in the event pool's buffer of their own. An open dashboard asks for its numbers each second and used to push the app's requests out of the pool within two minutes

### Changed

- Needs LowEvent 0.8.7

## 1.0.34

### Added

- The dashboard's bar and the request trees show the time each node takes to render and each query takes to run. Each is an event in its request's tree now

### Changed

- Needs LowEvent 0.8.6 and Antlers 1.5.8 and LowData 0.4.4 and LowLoop 0.8.14

## 1.0.33

### Added

- A bar at the top of the dashboard shows where an average request spends its time. Each kind of event is a segment as wide as its own time without the events it caused. Clicking it opens the requests

### Changed

- The system header shows a bigger deer without the words Raindeer System
- The Events page lists the nodes that observe "/*" as the wildcard event's observers. `WildcardEvent.observers` answers for its "/*" key
- The Events page lists every node that observes a route as the route event's observers instead of counting routes. `RouteEvent.observers` gathers them across the router's routes without "/*"
- The Events page lists what observes a status and what observes an interval too
- Needs Observers 1.1.3 and LowEvent 0.8.5 and LowLoop 0.8.13 whose events list their own observers

### Removed

- The line under the menu on the dashboard

## 1.0.32

### Changed

- Needs Raindown 0.25.4 which no longer depends on curses so Raindeer apps don't compile it

### Added

- The dashboard shows retained objects as a stat and a trend line. These have survived several garbage collections so they only climb when something holds on to them

### Removed

- The Events stat. It counted event types which never change and the Events page lists them

## 1.0.31

### Changed

- The system pages have Raindeer's deer in a bordered header that links to the app's home page, with the open page highlighted in the menu instead of a heading
- Cards, charts, tables and requests share one bordered card style in light and dark, with quieter labels and the version in the footer
- The Events page names an observing object by its class instead of its address in memory

## 1.0.30

### Added

- The dashboard's numbers refresh each second from `/system/stats` while the page is in view

### Changed

- Visitors is called "Visitors (5 min)"
- The system pages' own requests, like the dashboard refreshing itself, aren't counted as traffic or shown on the Requests page
- Needs LowNode 0.5.14, so a JSON response shows its request as answered

## 1.0.29

### Changed

- The dashboard shows requests per second, averaged over the last minute, and the busiest second in it, instead of requests in the last minute and requests kept

## 1.0.28

### Changed

- Visitors in the last 5 minutes and requests in the last minute count every request as it comes in, so they're no longer limited to the event pool's last 100. Visitors are kept as hashes of their address and forgotten after 5 minutes

## 1.0.27

### Added

- The dashboard shows visitors in the last 5 minutes and requests being answered now and open connections and how many requests are kept
- Each GET on the Requests page has a Visit button that opens its page

### Changed

- The dashboard's stats are four across in one grid. Long numbers shrink to fit their card and uptime is short like "2 h 5 min"
- The system pages' cards are spaced 10% tighter and their numbers and labels are 10% smaller
- Needs LowLoop 0.8.12 for its open connection count

### Fixed

- The system pages say they're UTF-8, so a separator like "·" no longer shows as "Â·"

## 1.0.26

### Fixed

- The system pages no longer fail with `uninitialized constant Raindeer::VERSION` from the released gem. Raindeer loads its version itself instead of relying on the gemspec to

## 1.0.25

### Fixed

- The gem includes `public/system`, so a site using the released gem gets the system pages' styles. 1.0.24 served them only from a checkout

## 1.0.24

### Changed

- Raindeer serves its own system files like `/system/system.css` before the app's, so they always match its version. An app's copy in `public/system` can be deleted
- The system pages link their files with `?v=` and Raindeer's version, so a browser or a cache like Cloudflare fetches them fresh after each release
- Needs LowLoop 0.8.11, which lets a second file server share the one file responder

## 1.0.23

### Added

- A Requests page at `/system/requests` lists the last 100 requests and opens each to show its event tree
- The dashboard shows requests in the last minute and typical and slowest response times and threads and live objects and garbage collections
- The dashboard lists each observed `Interval` with how often it runs and what observes it and when it last ran
- Live objects get a line each minute like memory and observed keys

### Changed

- The system pages keep to 1000px wide and the stat numbers fit on one line
- A trend line's area is filled to the bottom of its chart and a line that never changes runs across the middle

## 1.0.22

### Added

- `system_mode` turns the system pages at `/system` on or off, with `RAIN_SYSTEM` too. They're on while debugging unless it's set
- The dashboard shows memory and peak memory and observed keys and uptime, with a line of each minute's memory and keys for the last 3 hours from an `Interval`

### Changed

- Needs Observers 1.1.2, which doesn't keep every request's event tree in memory

## 1.0.21

### Added

- Nodes can write `observe Interval[every_minute: 5]`, as `LowNode::Interval` is LowLoop's `Low::Loop::Interval`

## 1.0.20

### Fixed

- A param that more than one route passes through, like `:slug` in `/shop/:slug` and `/shop/:slug/edit`, matches once, instead of once for each route, which sent its routes' events twice, like a form's `receive`, saving an upload twice

## 1.0.19

### Added

- A status event, like a 404's, gives its request's `cookies`, `path` and `query`, as route events do, so a status's page can show the site's layout as its visitor sees it and use the address it's for

## 1.0.18

### Added

- A form with a file input, sent as `multipart/form-data`, is parsed into `event.body` too: its fields as strings and its files as `Rain::Events::Multipart::UploadedFile`, with their filename, content type and data. A name sent more than once, like several files from one input, gives an array

## 1.0.17

### Fixed

- A form posted to a path only nodes observing `/*` answer, like a member's `/leaddog/edit`, calls their `receive` action with the form as `event.body`, instead of rendering the page without it

## 1.0.16

### Fixed

- An event's path is decoded, so a route matches, and a node finds content, at an address with letters like ü in it, which browsers send as %C3%BC

## 1.0.15

### Fixed

- `RAIN_DEBUG`, `RAIN_MATRIX` and `RAIN_MIRROR` take `true` and `false` as well as `1` and `0`. Any other value raises an error, where before it was ignored and left the config file's setting on, so `RAIN_DEBUG=false` left debug mode on in production

## 1.0.14

### Added

- `Rain::CrossOriginProtection` turns away a request another site's page makes, like a form it posts here, with a 403 before the router. It checks the browser's `Sec-Fetch-Site` header, or `Origin` in older browsers. Requests that aren't from a browser, like webhooks, go through

### Changed

- Need Observers 1.1.1 and LowEvent 0.8.4, which reorder observers, so `CrossOriginProtection` observes `RequestEvent` first

## 1.0.13

### Added

- `event.path`, the address a request came to without its query, on route, wildcard and render events. A route with a parameter, like `/posts/:slug`, has that as its `event.route.path`

### Changed

- Need LowData 0.4.1, for `LowData::Queries`, and Lowkey 0.7.4, which finds the methods after an RBX template

## 1.0.12

### Added

- `event.query`, a request's query string as a hash, on route, wildcard and render events

### Fixed

- A path with a query string, like `/search?q=rye`, routes as its path, rather than responding with a 404

## 1.0.11

### Added

- A child node's `RenderEvent` has its route's `request` and `cookies`, like a layout's

### Removed

- `Raindeer.request` and `Raindeer.cookies`, as render events have them

## 1.0.10

### Added

- `Raindeer.request` and `Raindeer.cookies`, the request being responded to, for nodes that aren't given its event, like a layout

## 1.0.9

### Added

- Every `RouteEvent` and `WildcardEvent` has its `request`, not only a `ReceiveEvent`
- `event.cookies`, the cookies a request sent, by name

## 1.0.6

### Fixed

- Requires `lowtype` 1.6.2 or later so `rain` doesn't raise "superclass mismatch for class ArgumentTypeError"

## 1.0.4

### Added

- `ReceiveEvent` with a `body` for requests with a body
- Route helpers for every HTTP verb (`query`, `put` and `patch` were missing)

### Fixed

- Remove the `update` route helper which raised an error

## 1.0.3

### Fixed

- Requests with a body crashed the router instead of calling `receive`

## 1.0.0

### Changed

- Build static files without trailing slashes

### Fixed

- Pass parent params from node parent to child

## 0.12.0

### Added

- Support translations

## 0.11.0

### Added

- Add an asset compile pipeline for CSS and JS
- Add lowdata

## 0.10.0

### Added

- List support `<{ list: item folder: 'cards' }>`
- Raindown write-back/replace markdown feature

## 0.9.10

### Changed

- Router: Use take instead of trigger
- Router: Rename mid-node handle action to side_effect action
- Router: Rename WildcardRouteEvent to WildcardEvent

## 0.9.0

### Added

- Expose `Rain.pages` API

## 0.8.0

### Added

- Export markdown files to html

## 0.7.0

### Added

- Support raindown
- Serve JS files
- Add `rain` CLI

## 0.6.0

### Added

- Support wildcard routes (`'/*'`)
- Support markdown pages

## 0.5.0

### Added

- Add leet flicker effect

### Changed

- Namespace system nodes
- Handle config path in config loader
- Refactor boot and router setup
- Refactor stream cell color data into color effect

## 0.4.0

### Added

- Dashboard, Events and Routes system pages
- Introduce debug mode with `RAIN_DEBUG`/`debug_mode` config

### Changed

- Load dev gems only when present
- Observe both generic and specific status event

### Fixed

- Fix matrix type expression bug

## 0.3.0

### Added

- Rain Matrix
- Event Pool
- Event Tree

## 0.2.0

### Added

- LowLoad + RBX + Antlers
- Layout node, error 404 node
- Theme system nodes
- Rain Matrix

## 0.1.0

### Added

- Config and config loader

## 0.0.0

### Added

- Basic template
