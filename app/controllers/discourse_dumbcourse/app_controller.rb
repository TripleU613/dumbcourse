# frozen_string_literal: true

require "rack/mime"

module DiscourseDumbcourse
  class AppController < ::ActionController::Base
    include ::CurrentUser

    layout false
    before_action :relax_security_headers
    before_action :redirect_anonymous_to_login

    def show
      public_root = DiscourseDumbcourse::Engine.root.join("public")
      request_path = params[:path].to_s

      if request_path != ""
        safe_path = Pathname.new(request_path).cleanpath.to_s
        safe_path = safe_path.sub(%r{\A\.+/}, "")
        file_path = public_root.join(safe_path)

        if file_path.file?
          response.headers["Cache-Control"] = "public, max-age=31536000, immutable"
          return send_data(
            File.binread(file_path),
            disposition: "inline",
            type: Rack::Mime.mime_type(file_path.to_s, "application/octet-stream"),
          )
        end
      end

      index_path = public_root.join("index.html")
      unless index_path.file?
        return render plain: "Dumbcourse index missing", status: 500
      end

      response.headers["Cache-Control"] = "no-store"
      html = File.read(index_path)
      settings = {
        defaultTheme: SiteSetting.dumbcourse_default_theme,
      }
      settings_script = "<script>window.DUMBCOURSE_SETTINGS=#{settings.to_json};</script>"
      if html.include?("</head>")
        html = html.sub("</head>", "#{settings_script}</head>")
      else
        html = settings_script + html
      end
      render plain: html, content_type: "text/html; charset=utf-8"
    end

    private

    def login_path_request?
      path = params[:path].to_s
      return true if path == "login" || path.start_with?("login/")
      return true if path == "signup" || path.start_with?("signup/")
      return true if path == "register" || path.start_with?("register/")
      return true if path == "emoji_map.json"
      false
    end

    def redirect_anonymous_to_login
      return if authenticated?
      return if login_path_request?

      redirect_to "#{Discourse.base_path}/dumb/login"
    end

    def authenticated?
      current_user.present? || CurrentUser.has_auth_cookie?(request.env)
    end

    def relax_security_headers
      response.headers["Content-Security-Policy"] =
        "default-src * data: blob: 'unsafe-inline' 'unsafe-eval' http: https:;"
      response.headers["Cross-Origin-Opener-Policy"] = "unsafe-none"
      response.headers["Cross-Origin-Embedder-Policy"] = "unsafe-none"
      response.headers["Cross-Origin-Resource-Policy"] = "cross-origin"
      response.headers["X-Frame-Options"] = "ALLOWALL"
      response.headers.delete("X-Content-Type-Options")
      response.headers.delete("X-XSS-Protection")
      response.headers["Referrer-Policy"] = "unsafe-url"
      response.headers["X-Permitted-Cross-Domain-Policies"] = "all"
      response.headers.delete("Permissions-Policy")
    end
  end
end
