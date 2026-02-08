# frozen_string_literal: true

module DiscourseDumbcourse
  class SseController < ::ActionController::Base
    requires_plugin DiscourseDumbcourse::PLUGIN_NAME
    include ActionController::Live

    skip_before_action :verify_authenticity_token

    # GET /<base>/push/sse/:topic
    # SSE endpoint backed by Redis SUBSCRIBE
    def stream
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

      begin
        redis = Redis.new(DiscourseRedis.config.dup)

        # Heartbeat thread to prevent nginx proxy timeout
        heartbeat_thread =
          Thread.new do
            loop do
              sleep 30
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
        heartbeat_thread&.kill
        redis&.close
        response.stream.close
      end
    end
  end
end
