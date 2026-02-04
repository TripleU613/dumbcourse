# frozen_string_literal: true

module DiscourseDumbcourse
  class PushController < ::ApplicationController
    if respond_to?(:requires_plugin)
      requires_plugin DiscourseDumbcourse::PLUGIN_NAME
    end
    requires_login except: [:server_info]
    skip_before_action :verify_authenticity_token

    # GET /dumb/push/info
    # Returns ntfy server URL for the app to use
    def server_info
      render json: {
        server: SiteSetting.dumbcourse_ntfy_server,
        enabled: SiteSetting.dumbcourse_push_enabled
      }
    end

    # POST /dumb/push/register
    # Register a device for push notifications
    def register
      topic = params[:topic].to_s.strip
      device_id = params[:device_id].to_s.strip

      if topic.blank? || device_id.blank?
        return render json: { error: "topic and device_id required" }, status: :bad_request
      end

      # Store the mapping: user_id -> { device_id, topic }
      devices = PluginStore.get("dumbcourse", "push_devices_#{current_user.id}") || {}
      devices[device_id] = {
        topic: topic,
        registered_at: Time.now.iso8601,
        user_agent: request.user_agent
      }
      PluginStore.set("dumbcourse", "push_devices_#{current_user.id}", devices)

      render json: { success: true, topic: topic }
    end

    # DELETE /dumb/push/unregister
    # Unregister a device
    def unregister
      device_id = params[:device_id].to_s.strip

      if device_id.blank?
        return render json: { error: "device_id required" }, status: :bad_request
      end

      devices = PluginStore.get("dumbcourse", "push_devices_#{current_user.id}") || {}
      devices.delete(device_id)
      PluginStore.set("dumbcourse", "push_devices_#{current_user.id}", devices)

      render json: { success: true }
    end

    # GET /dumb/push/status
    # Check registration status for current user
    def status
      device_id = params[:device_id].to_s.strip
      devices = PluginStore.get("dumbcourse", "push_devices_#{current_user.id}") || {}

      if device_id.present?
        device = devices[device_id]
        render json: {
          registered: device.present?,
          topic: device&.dig("topic"),
          device_count: devices.size
        }
      else
        render json: {
          device_count: devices.size,
          devices: devices.keys
        }
      end
    end
  end
end
