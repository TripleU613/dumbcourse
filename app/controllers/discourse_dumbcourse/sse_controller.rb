# frozen_string_literal: true

module DiscourseDumbcourse
  class SseController < ::ActionController::Base
    requires_plugin DiscourseDumbcourse::PLUGIN_NAME

    skip_before_action :verify_authenticity_token

    # GET /<base>/push/sse/:topic
    #
    # SSE is disabled.  The SPA client already uses polling for badge counts
    # instead of holding an SSE connection.  Keeping ActionController::Live
    # here was the root cause of total worker exhaustion — each open SSE
    # connection held a Pitchfork worker for up to 120 s, and with only 8
    # workers the site became unresponsive.
    #
    # Push notifications are still delivered via Redis PUBLISH → the
    # PushSender publishes, and any future lightweight listener (e.g.
    # a standalone Puma or a thin SSE proxy) can subscribe without
    # tying up Discourse workers.
    def stream
      render plain: "SSE disabled — use polling", status: :service_unavailable
    end
  end
end
