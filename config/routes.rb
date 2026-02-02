# frozen_string_literal: true

DiscourseDumbcourse::Engine.routes.draw do
  get "/" => "app#show"
  get "/*path" => "app#show"
end

Discourse::Application.routes.draw do
  mount ::DiscourseDumbcourse::Engine, at: "/dumb"
end
