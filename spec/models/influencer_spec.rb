require 'rails_helper'

RSpec.describe Influencer, type: :model do
  # Teste se o modelo é válido com todos os atributos
  it "is valid with valid attributes" do
    influencer = Influencer.new(
      name: "John Doe",
      username: "johndoe",
      platform: "Instagram",
      followers: 1000,
      email: "john.doe@example.com"
    )
    expect(influencer).to be_valid
  end

  # Teste se o modelo não é válido sem nome
  it "is not valid without a name" do
    influencer = Influencer.new(
      username: "johndoe",
      platform: "Instagram",
      followers: 1000,
      email: "john.doe@example.com"
    )
    expect(influencer).to_not be_valid
  end

  # Teste se o modelo não é válido sem plataforma
  it "is not valid without a platform" do
    influencer = Influencer.new(
      name: "John Doe",
      username: "johndoe",
      followers: 1000,
      email: "john.doe@example.com"
    )
    expect(influencer).to_not be_valid
  end

  # Teste se o modelo não é válido sem email
  it "is not valid without an email" do
    influencer = Influencer.new(
      name: "John Doe",
      username: "johndoe",
      platform: "Instagram",
      followers: 1000
    )
    expect(influencer).to_not be_valid
  end
end
