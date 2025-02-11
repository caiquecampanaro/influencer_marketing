class ApplicationController < ActionController::API
  def serve_verification_file
    file_path = Rails.public_path.join('auth', 'callback', 'tiktokETtTSguI5Nu5gFu5UV2d7ZcFJTQR99xE.txt')
    
    if File.exist?(file_path)
      content = File.read(file_path)
      render plain: content, content_type: 'text/plain'
    else
      render plain: 'File not found', status: :not_found
    end
  end
end
