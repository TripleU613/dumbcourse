# frozen_string_literal: true

module DiscourseDumbcourse
  class SseController < ::ActionController::Base
    requires_plugin DiscourseDumbcourse::PLUGIN_NAME
    include ActionController::Live

    skip_before_action :verify_authenticity_token

    # Maximum time a single SSE connection can hold a worker (seconds).
    # Clients must reconnect after this. Keeps workers from being held forever.
    MAX_CONNECTION_SECONDS = 120

    # GET /<base>/push/sse/:topic
    # SSE endpoint backed by Redis SUBSCRIBE with a hard timeout so we never
    # hold a Unicorn/Pitchfork worker indefinitely.
    def stream
      unless SiteSetting.dumbcourse_push_enabled
        render plain: "push disabled", status: :service_unavailable
        return
      end

      topic = params[:topic].to_s.strip
      if topic.blank?
        render plain: "topic required", status: :bad_request
        return
      end

      channel = "dumbcourse_push:#{topic}"

      response.headers["Content-Type"] = "text/event-stream"
      response.headers["X-Accel-Buffering"] = "no"
      response.headers["Cache-Control"] = "no-cache"

      redis = nil
      heartbeat_thread = nil
      timeout_thread = nil

      begin
        redis = Redis.new(DiscourseRedis.config.dup)

        # Hard timeout — unsubscribe after MAX_CONNECTION_SECONDS so the worker is freed.
        # The client will see the stream end and should reconnect.
        timeout_thread =
          Thread.new do
            sleep MAX_CONNECTION_SECONDS
            begin
              response.stream.write("event: reconnect\ndata: {\"reason\":\"timeout\"}\n\n")
            rescue
              nil
            end
            redis&.unsubscribe(channel) rescue nil
          end

        # Heartbeat to prevent intermediate proxy timeouts
        heartbeat_thread =
          Thread.new do
            loop do
              sleep 25
              begin
                response.stream.write(": keepalive\n\n")
              rescue => e
                Rails.logger.debug("[Dumbcourse Push] Heartbeat stopped: #{e.message}")
                break
              end
            end
          end

        redis.subscribe(channel) do |on|
          on.message do |_ch, message|
            begin
              response.stream.write("event: message\ndata: #{message}\n\n")
            rescue => e
              Rails.logger.debug("[Dumbcourse Push] Stream write failed: #{e.message}")
              redis.unsubscribe(channel)
            end
          end
        end
      rescue => e
        Rails.logger.debug("[Dumbcourse Push] SSE connection closed: #{e.message}")
      ensure
        timeout_thread&.kill
        heartbeat_thread&.kill
        redis&.close
        response.stream.close
      end
    end
  end
end
