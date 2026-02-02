# frozen_string_literal: true

require "rack/mime"

module DiscourseDumbcourse
  class AppController < ::ActionController::Base
    layout false

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
      render plain: File.read(index_path), content_type: "text/html; charset=utf-8"
    end
  end
end
