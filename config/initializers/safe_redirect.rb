# Configuração para permitir redirecionamentos externos
Rails.application.config.action_controller.raise_on_open_redirects = false

# Lista de hosts permitidos para redirecionamento
Rails.application.config.hosts << "www.tiktok.com"
Rails.application.config.hosts << "open.tiktokapis.com"
