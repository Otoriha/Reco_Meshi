# Google Cloud Vision API Configuration
Rails.application.configure do
  # Google Cloud認証の設定
  if Rails.env.development? || Rails.env.production?
    begin
      # 環境変数からBase64エンコードされた認証情報を取得
      credentials_base64 = ENV['GOOGLE_CLOUD_CREDENTIALS']
      project_id = ENV['GOOGLE_CLOUD_PROJECT_ID']

      if credentials_base64.present? && project_id.present?
        # Base64デコードしてJSONに変換
        credentials_json = Base64.decode64(credentials_base64)
        
        # tmpディレクトリの確認と作成
        tmp_dir = Rails.root.join('tmp')
        FileUtils.mkdir_p(tmp_dir) unless Dir.exist?(tmp_dir)
        
        # 一時ファイルに書き出し
        credentials_file = tmp_dir.join('google_cloud_credentials.json')
        File.write(credentials_file, credentials_json)
        
        # 環境変数に設定
        ENV['GOOGLE_APPLICATION_CREDENTIALS'] = credentials_file.to_s
        ENV['GOOGLE_CLOUD_PROJECT'] = project_id
        
        Rails.logger.info "Google Cloud Vision API credentials configured successfully"
      else
        Rails.logger.warn "Google Cloud Vision API credentials not found in environment variables"
      end
    rescue => e
      Rails.logger.error "Failed to configure Google Cloud Vision API: #{e.message}"
      # 開発環境では例外を再発生させない（本番では適宜調整）
      raise e if Rails.env.production?
    end
  end
end