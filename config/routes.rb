# frozen_string_literal: true

DiscourseDumbcourse::Engine.routes.draw do
  post "/hcaptcha" => "app#hcaptcha"

  # Push notification endpoints
  get "/push/info" => "push#server_info"
  post "/push/register" => "push#register"
  delete "/push/unregister" => "push#unregister"
  get "/push/status" => "push#status"

  # Main app routes (catch-all)
  get "/" => "app#show"
  get "/*path" => "app#show"
end

Discourse::Application.routes.draw do
  mount ::DiscourseDumbcourse::Engine, at: "/dumb"
end
