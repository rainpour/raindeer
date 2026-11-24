# frozen_string_literal: true

require 'lowdata'
require 'lowevent'
require 'lownode'
require 'lowtype'
require 'observers'
require 'plugs'
require 'providers'

# File paths are relative to the directory where the process is run from, so the app can just require this boot file.

#################################################
# FRAMEWORK INTERNAL API
#################################################

module Rain
  require_relative '../support/config_loader'
  env = {
    host: ENV.fetch('RAIN_HOST', nil),
    port: ConfigLoader.parse_integer(ENV.fetch('RAIN_PORT', nil)),
    web_root: ENV.fetch('RAIN_WEB_ROOT', nil),
    debug_mode: ConfigLoader.parse_boolean(ENV.fetch('RAIN_DEBUG', nil)),
    matrix_mode: ConfigLoader.parse_boolean(ENV.fetch('RAIN_MATRIX', nil)),
    mirror_mode: ConfigLoader.parse_boolean(ENV.fetch('RAIN_MIRROR', nil)),
    system_mode: ConfigLoader.parse_boolean(ENV.fetch('RAIN_SYSTEM', nil))
  }
  config_path = File.expand_path('config/config.yaml', Dir.pwd)
  config = ConfigLoader.load(config_path, env)
  # The system pages at /system are on while debugging unless a setting says otherwise.
  config.system_mode = config.debug_mode if config.system_mode.nil?

  Providers.define('rain.config') { config }

  require_relative '../translations/translations'
  Translations.load(source_locale: config.source_locale)

  Providers.define('rain.router') do
    require_relative '../router/router'
    Router.new
  end

  Providers.define('rain.matrix') do
    require_relative '../matrix/matrix'
    Matrix.new(event_pool: Providers['low.event.pool'])
  end

  Providers.define('low.loop') do
    if config.assets
      require_relative '../assets/assets'
      assets = Assets.new(web_root: config.web_root, bundles: config.assets)
      assets.build
      assets.watch if config.debug_mode
    end

    require 'lowloop'
    # The system pages' own requests go in a buffer of their own like interval ticks so they never push the app's out.
    Providers['low.event.pool'].keep_apart do |event|
      event.is_a?(Low::Events::RequestEvent) && event.request.path.to_s.start_with?('/system')
    end
    low_loop = LowLoop.new(config:, router: Providers['rain.router'], renderer: Providers['rain.matrix'])

    # Raindeer's own files, like the system pages' styles, come before the app's, so they always match this version.
    raindeer_files = Low::FileServer.new(web_root: File.expand_path('../../public', __dir__), content_types: config.content_types,
                                         cache_control: config.cache_control)

    # A request from another site's page is turned away before anything else answers it.
    require_relative '../security/cross_origin_protection'
    # With the system pages on, each request is counted for the dashboard first, before anything can answer it.
    traffic = System::Traffic if config.system_mode
    Low::Events::RequestEvent.define { |observers| [*traffic, Rain::CrossOriginProtection, raindeer_files, *observers] }
    low_loop
  end
end

#################################################
# FRAMEWORK EXTERNAL API
#################################################

require_relative 'integrations'
require_relative 'raindeer'

#################################################
# APPLICATION CODE
#################################################

require 'antlers' # Adds antlers support to dirload.
require 'dirload'
dirload(File.expand_path('../system', __dir__))

application_path = File.expand_path('app', Dir.pwd)

if Dir.exist?(application_path)
  metadata = dirload(application_path)

  if Dir.exist?(File.expand_path('pages', application_path))
    Providers.define('rain.pages', eager: true) do
      require_relative '../pages/pages'
      Rain::Pages.new(metadata:)
    end
  end
end

#################################################
# FRAMEWORK INTERNAL CLEANUP
#################################################

Lowkey.clear
