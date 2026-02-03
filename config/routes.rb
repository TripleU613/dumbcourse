# frozen_string_literal: true

DiscourseDumbcourse::Engine.routes.draw do
  post "/hcaptcha" => "app#hcaptcha"

  # Push notification endpoints (must be before catch-all)
  scope "/push", defaults: { format: :json } do
    get "/info" => "push#server_info"
    post "/register" => "push#register"
    delete "/unregister" => "push#unregister"
    get "/status" => "push#status"
  end

  # Main app routes (catch-all) - exclude push paths
  get "/" => "app#show"
  get "/*path" => "app#show", constraints: lambda { |req| !req.path.start_with?("/dumb/push") }
end

Discourse::Application.routes.draw do
  mount ::DiscourseDumbcourse::Engine, at: "/dumb"
end
