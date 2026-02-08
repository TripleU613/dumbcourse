# frozen_string_literal: true

DiscourseDumbcourse::Engine.routes.draw do
  post "/hcaptcha" => "app#hcaptcha"

  # Push notification endpoints (must be before catch-all)
  scope "/push", defaults: { format: :json } do
    get "/info" => "push#server_info"
    post "/register" => "push#register"
    delete "/unregister" => "push#unregister"
    get "/status" => "push#status"
    get "/preferences" => "push#preferences"
    put "/preferences" => "push#update_preferences"
    post "/test" => "push#test_push"
  end

  # Self-hosted ntfy SSE endpoint (must be before catch-all)
  scope "/ntfy" do
    get "/:topic/sse" => "ntfy#sse"
  end

  # Main app routes (catch-all) - exclude push and ntfy paths
  get "/" => "app#show"
  get "/*path" => "app#show",
      :constraints => ->(req) do
        base = DiscourseDumbcourse.base_path_with_slash
        !req.path.start_with?("#{base}/push") && !req.path.start_with?("#{base}/ntfy")
      end
end

class DiscourseDumbcourseBasePathConstraint
  def matches?(req)
    req.params[:dumbcourse_base_path].to_s == DiscourseDumbcourse.base_path
  end
end

Discourse::Application.routes.draw do
  constraints DiscourseDumbcourseBasePathConstraint.new do
    scope "/:dumbcourse_base_path" do
      mount ::DiscourseDumbcourse::Engine, at: "/"
    end
  end
end
