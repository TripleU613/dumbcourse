# frozen_string_literal: true

# name: discourse-dumbcourse
# about: Serve the Dumbcourse SPA under /dumb
# version: 0.1
# authors: TripleU
# url: https://forums.dietdroid.com
# required_version: 2.7.0

module ::DiscourseDumbcourse
  PLUGIN_NAME = "discourse-dumbcourse"
end

require_relative "lib/discourse_dumbcourse/engine"

after_initialize do
  enabled_site_setting :dumbcourse_enabled
end
