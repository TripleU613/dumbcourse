# frozen_string_literal: true

require "rack/mime"
require "cgi"

module DiscourseDumbcourse
  class AppController < ::ActionController::Base
    include ::CurrentUser

    layout false
    before_action :relax_security_headers
    before_action :redirect_anonymous_to_login

    def show
      if login_page?
        response.headers["Cache-Control"] = "no-store"
        return render plain: login_html, content_type: "text/html; charset=utf-8"
      end

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
      render plain: File.read(index_path), content_type: "text/html; charset=utf-8"
    end

    private

    def login_page?
      current_user.nil? && login_path_request?
    end

    def login_path_request?
      path = params[:path].to_s
      path == "login" || path.start_with?("login/")
    end

    def redirect_anonymous_to_login
      return unless current_user.nil?
      return if login_path_request?

      redirect_to "#{Discourse.base_path}/dumb/login"
    end

    def login_html
      return_path = "#{Discourse.base_path}/dumb"
      login_url = "/login?return_path=#{CGI.escape(return_path)}"
      signup_url = "/signup?return_path=#{CGI.escape(return_path)}"

      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta http-equiv="X-UA-Compatible" content="IE=edge">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>Sign In</title>
          <style>
            body{margin:0;padding:0;background:#111;color:#eee;font-family:Arial,Helvetica,sans-serif}
            .wrap{max-width:520px;margin:40px auto;padding:24px}
            h1{margin:0 0 8px 0;font-size:22px}
            p{margin:0 0 18px 0;color:#bbb;font-size:14px}
            a.btn{display:block;text-align:center;text-decoration:none;padding:12px 14px;border-radius:6px;margin:10px 0;border:1px solid #333;background:#1f1f1f;color:#fff}
            a.btn.secondary{background:#151515;color:#ddd}
            .note{margin-top:16px;color:#777;font-size:12px}
          </style>
        </head>
        <body>
          <div class="wrap">
            <h1>Sign in</h1>
            <p>Use your forum account to continue.</p>
            <a class="btn" href="#{login_url}">Log in</a>
            <a class="btn secondary" href="#{signup_url}">Create account</a>
            <div class="note">This page uses the forum sign-in.</div>
          </div>
        </body>
        </html>
      HTML
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
