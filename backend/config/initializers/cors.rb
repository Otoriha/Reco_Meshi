# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Configure origins based on environment
    if Rails.env.development?
      # Development environment - Allow local hosts
      origins "localhost:3001",     # Frontend (Web)
              "localhost:3002",     # LIFF
              "https://localhost:3002", # LIFF (HTTPS)
              "127.0.0.1:3001",    # Alternative localhost
              "127.0.0.1:3002",    # Alternative localhost
              "https://127.0.0.1:3002", # Alternative localhost (HTTPS)
              "0.0.0.0:3001",      # Docker network
              "0.0.0.0:3002",      # Docker network
              "https://0.0.0.0:3002" # Docker network (HTTPS)
    else
      # Production environment - Allow specific domains
      allowed_origins = []
      
      # Frontend URLs (Vercel or custom domain)
      if ENV["FRONTEND_URL"].present?
        allowed_origins += ENV["FRONTEND_URL"].split(",").map(&:strip)
      else
        # Fallback for direct domain specification
        allowed_origins << "https://reco-meshiweb.vercel.app"
      end
      
      # LIFF URLs (Vercel or custom domain)
      if ENV["LIFF_URL"].present?
        allowed_origins += ENV["LIFF_URL"].split(",").map(&:strip)
      end
      
      # Default Vercel preview URLs (optional - remove in production for security)
      if ENV["ALLOW_VERCEL_PREVIEW"] == "true"
        allowed_origins << /https:\/\/.*\.vercel\.app/
      end
      
      # Apply origins
      origins *allowed_origins if allowed_origins.any?
    end

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      expose: ["Authorization", "X-Total-Count", "X-Page", "X-Per-Page"] # フロントからAuthorizationヘッダーを参照可能に
  end
end
