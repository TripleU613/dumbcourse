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

  # Hook: New post created (handles replies)
  on(:post_created) do |post, opts, user|
    next unless SiteSetting.dumbcourse_push_enabled
    next if post.post_type != Post.types[:regular]

    Jobs.enqueue_in(5.seconds, :dumbcourse_push_notify, post_id: post.id, type: "post_created")
  end

  # Hook: User mentioned
  on(:user_mentioned) do |post, mentioned_user|
    next unless SiteSetting.dumbcourse_push_enabled

    Jobs.enqueue_in(
      2.seconds,
      :dumbcourse_push_notify,
      post_id: post.id,
      type: "mention",
      target_user_id: mentioned_user.id
    )
  end

  # Hook: Post liked
  on(:post_liked) do |post, post_action, liker|
    next unless SiteSetting.dumbcourse_push_enabled

    Jobs.enqueue_in(
      3.seconds,
      :dumbcourse_push_notify,
      post_id: post.id,
      type: "liked",
      liker_user_id: liker.id
    )
  end

  # Hook: User quoted
  on(:user_quoted) do |post, quoted_user|
    next unless SiteSetting.dumbcourse_push_enabled

    Jobs.enqueue_in(
      2.seconds,
      :dumbcourse_push_notify,
      post_id: post.id,
      type: "quoted",
      target_user_id: quoted_user.id
    )
  end

  # Background job for sending push notifications
  module ::Jobs
    class DumbcoursePushNotify < ::Jobs::Base
      def execute(args)
        return unless SiteSetting.dumbcourse_push_enabled

        post = Post.find_by(id: args[:post_id])
        return unless post

        case args[:type]
        when "post_created"
          if post.topic&.private_message?
            DiscourseDumbcourse::PushSender.notify_pm(post)
          else
            DiscourseDumbcourse::PushSender.notify_reply(post)
          end
        when "mention"
          DiscourseDumbcourse::PushSender.notify_mention(post, args[:target_user_id])
        when "liked"
          liker = User.find_by(id: args[:liker_user_id])
          DiscourseDumbcourse::PushSender.notify_liked(post, liker) if liker
        when "quoted"
          DiscourseDumbcourse::PushSender.notify_quoted(post, args[:target_user_id])
        end
      end
    end
  end
end
