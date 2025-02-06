# Influencer Marketing

Este projeto é uma aplicação de marketing de influenciadores, onde dados de influenciadores são sincronizados de uma API externa e salvos em um banco de dados.

## Pré-requisitos

- Ruby 3.3.6
- Rails 8.0.1
- PostgreSQL
- Bundler 

## Instalação

1. Clone este repositório:
   git clone git@github.com:caiquecampanaro/influencer_marketing.git

2. Navegue até a pasta do projeto:
cd influencer_marketing

3. Instale as dependências do Ruby:
bundle install

4. Configure o banco de dados:
rails db:create
rails db:migrate

5. Inicie o servidor Rails:
rails s

6. Acesse postman com requisição GET:
URL: http://localhost:3000/api/v1/sync

7. Para rodar os testes do projeto, utilize:
rspec
