# frozen_string_literal: true

# name: discourse-dumbcourse
# about: Serve the Dumbcourse SPA under /dumb with push notifications
# version: 0.2
# authors: TripleU
# url: https://github.com/TripleU613/dumbcourse
# required_version: 2.7.0

module ::DiscourseDumbcourse
  PLUGIN_NAME = "discourse-dumbcourse"

  def self.base_path
    path = SiteSetting.dumbcourse_base_path.to_s.strip
    path = "dumb" if path.blank?
    path = path.sub(%r{\A/+}, "").sub(%r{/+\z}, "")
    path = "dumb" if path.blank?
    path
  end

  def self.base_path_with_slash
    "/#{base_path}"
  end

  module RequiresPluginFallback
    def requires_plugin(*)
      # no-op for older Discourse versions
    end
  end
end

unless ::ActionController::Base.respond_to?(:requires_plugin)
  ::ActionController::Base.extend(::DiscourseDumbcourse::RequiresPluginFallback)
end

require_relative "lib/discourse_dumbcourse/engine"
require_relative "lib/discourse_dumbcourse/push_sender"

after_initialize do
  enabled_site_setting :dumbcourse_enabled

  # Hook: Notification created
  on(:notification_created) do |notification|
    next unless SiteSetting.dumbcourse_push_enabled

    Jobs.enqueue_in(
      2.seconds,
      :dumbcourse_push_notify,
      notification_id: notification.id,
    )
  end

  # Background job for sending push notifications
  module ::Jobs
    class DumbcoursePushNotify < ::Jobs::Base
      def execute(args)
        return unless SiteSetting.dumbcourse_push_enabled

        notification = Notification.find_by(id: args[:notification_id])
        return unless notification

        DiscourseDumbcourse::PushSender.notify_notification(notification)
      end
    end
  end
end
