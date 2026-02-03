# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module DiscourseDumbcourse
  class PushSender
    def self.send_to_user(user_id, title:, message:, click_url: nil, priority: "default")
      return unless SiteSetting.dumbcourse_push_enabled

      devices = PluginStore.get("dumbcourse", "push_devices_#{user_id}") || {}
      return if devices.empty?

      server = SiteSetting.dumbcourse_ntfy_server.to_s.strip
      server = "https://ntfy.sh" if server.blank?

      devices.each do |device_id, device_info|
        topic = device_info["topic"]
        next if topic.blank?

        send_notification(
          server: server,
          topic: topic,
          title: title,
          message: message,
          click_url: click_url,
          priority: priority
        )
      end
    end

    def self.send_notification(server:, topic:, title:, message:, click_url: nil, priority: "default")
      uri = URI.parse("#{server}/#{topic}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 5
      http.read_timeout = 10

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "application/json"

      # Optional: Add auth token if configured
      auth_token = SiteSetting.dumbcourse_ntfy_token.to_s.strip
      request["Authorization"] = "Bearer #{auth_token}" if auth_token.present?

      payload = {
        topic: topic,
        title: title.to_s[0..99], # ntfy title limit
        message: message.to_s[0..4095], # ntfy message limit
        priority: map_priority(priority)
      }

      payload[:click] = click_url if click_url.present?

      request.body = payload.to_json

      begin
        response = http.request(request)
        if response.code.to_i >= 400
          Rails.logger.warn("[Dumbcourse Push] Failed to send to #{topic}: #{response.code} #{response.body}")
        end
      rescue StandardError => e
        Rails.logger.error("[Dumbcourse Push] Error sending to #{topic}: #{e.message}")
      end
    end

    def self.map_priority(priority)
      case priority.to_s
      when "urgent", "high"
        5
      when "low"
        2
      when "min"
        1
      else
        3 # default
      end
    end

    # Notification type handlers
    def self.notify_reply(post)
      return unless post.topic
      return if post.post_number == 1 # Skip OP

      # Notify topic creator
      topic_user_id = post.topic.user_id
      if topic_user_id && topic_user_id != post.user_id
        send_to_user(
          topic_user_id,
          title: "New reply in: #{post.topic.title.truncate(50)}",
          message: "#{post.user.username}: #{post.excerpt(150, strip_links: true, strip_images: true, post: post)}",
          click_url: "#{Discourse.base_url}/dumb/t/#{post.topic.slug}/#{post.topic.id}/#{post.post_number}",
          priority: "default"
        )
      end

      # Notify users who are watching the topic
      TopicUser.where(
        topic_id: post.topic_id,
        notification_level: TopicUser.notification_levels[:watching]
      ).where.not(user_id: post.user_id).find_each do |tu|
        send_to_user(
          tu.user_id,
          title: "New reply in: #{post.topic.title.truncate(50)}",
          message: "#{post.user.username}: #{post.excerpt(150, strip_links: true, strip_images: true, post: post)}",
          click_url: "#{Discourse.base_url}/dumb/t/#{post.topic.slug}/#{post.topic.id}/#{post.post_number}",
          priority: "default"
        )
      end
    end

    def self.notify_mention(post, mentioned_user_id)
      return if mentioned_user_id == post.user_id

      user = User.find_by(id: mentioned_user_id)
      return unless user

      send_to_user(
        mentioned_user_id,
        title: "#{post.user.username} mentioned you",
        message: post.excerpt(150, strip_links: true, strip_images: true, post: post),
        click_url: "#{Discourse.base_url}/dumb/t/#{post.topic.slug}/#{post.topic.id}/#{post.post_number}",
        priority: "high"
      )
    end

    def self.notify_pm(post)
      return unless post.topic&.private_message?

      post.topic.topic_allowed_users.where.not(user_id: post.user_id).find_each do |tau|
        send_to_user(
          tau.user_id,
          title: "Private message from #{post.user.username}",
          message: post.excerpt(150, strip_links: true, strip_images: true, post: post),
          click_url: "#{Discourse.base_url}/dumb/t/#{post.topic.slug}/#{post.topic.id}/#{post.post_number}",
          priority: "high"
        )
      end
    end

    def self.notify_quoted(post, quoted_user_id)
      return if quoted_user_id == post.user_id

      send_to_user(
        quoted_user_id,
        title: "#{post.user.username} quoted you",
        message: "In: #{post.topic.title.truncate(50)}",
        click_url: "#{Discourse.base_url}/dumb/t/#{post.topic.slug}/#{post.topic.id}/#{post.post_number}",
        priority: "default"
      )
    end

    def self.notify_liked(post, liker_user)
      return if post.user_id == liker_user.id

      send_to_user(
        post.user_id,
        title: "#{liker_user.username} liked your post",
        message: post.excerpt(100, strip_links: true, strip_images: true, post: post),
        click_url: "#{Discourse.base_url}/dumb/t/#{post.topic.slug}/#{post.topic.id}/#{post.post_number}",
        priority: "low"
      )
    end
  end
end
