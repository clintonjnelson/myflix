require 'spec_helper'

describe StripeWrapper, :vcr do
  context "with Stripe API key loaded in ENV variable" do
    it "loads the correct API key" do
      expect(StripeWrapper.set_api_key).to eq(ENV['STRIPE_TEST_SECRET_KEY'])
    end
  end
end


describe StripeWrapper::Customer, :vcr do
  let(:token) { Stripe::Token.create(:card => {:number => card_number,
                                               :exp_month => 12,
                                               :exp_year => 2016,
                                               :cvc => "333" }).id }
  let(:joe) { Fabricate(:user, email: 'joeuser@example.com') }
  let(:card_number) { "4242424242424242" }
  let(:customer) { StripeWrapper::Customer.create(user: joe, card: token, plan: 'myflix_base') }

  before { StripeWrapper.set_api_key }

  context "with a valid request" do
    it "makes a new customer in Stripe" do
      expect(customer.response).to be_a Stripe::Customer
    end
    it "returns the Customer id" do
      expect(customer.response['id']).to be_present
    end
    it "saves the card in the Stripe list of cards" do
      expect(customer.response['cards']['total_count']).to eq(1)
    end
    it "makes a new plan subscription for the user" do
      expect(customer.response['subscriptions']['data'][0]['plan']['id']).to eq('myflix_base')
    end
    it "returns successful? is true" do
      expect(customer).to be_successful
    end
  end

  context "with invalid information in the request" do
    context "(specifically invalid card info)" do
      it "raises an error in the Stripe process" do
        response = StripeWrapper::Customer.create(user: joe, card: "not-a-card", plan: 'myflix_base')
        expect(response).to_not be_successful
      end
    end
    context "(specifically invalid plan info)" do
      it "raises an error in the Stripe process" do
        response = StripeWrapper::Customer.create(user: joe, card: token, plan: 'not-a-plan')
        expect(response).to_not be_successful
      end
    end
  end
end


describe StripeWrapper::Charge, :vcr do
  let(:email)    { 'joeuser@example.com' }
  let(:token)    { Stripe::Token.create(:card => {:number => card_number,
                                                  :exp_month => 12,
                                                  :exp_year => 2016,
                                                  :cvc => "333" }).id }
  before { StripeWrapper.set_api_key }

  context "with valid charge using card only(no customer)" do
    let(:card_number) { "4242424242424242" }
    let(:charge) { StripeWrapper::Charge.create(card: token, amount: 999, description: "test") }

    it "successfully charges the card" do
      expect(charge).to be_successful
    end
    it "charges 999 to the card" do
      expect(charge.response.amount).to eq(999)
    end
  end

  context "with valid charge using customer" do
    let(:card_number) { "4242424242424242" }
    let(:joe) { Fabricate(:user, email: 'joeuser@example.com') }
    let(:customer) { StripeWrapper::Customer.create(user: joe, card: token, plan: 'myflix_base') }

    it "successfully charges the card" do
      charge = StripeWrapper::Charge.create(customer: customer.response['id'], amount: 999, description: "test")
      expect(charge).to be_successful
    end
    it "charges 999 to the card" do
      charge = StripeWrapper::Charge.create(customer: customer.response['id'], amount: 999, description: "test")
      expect(charge.response.amount).to eq(999)
    end
  end

  context "with invalid card info" do
    let(:card_number) { "4000000000000002" }
    let(:charge)      { StripeWrapper::Charge.create(card: token, amount: 999, description: "test") }

    it "does not successfully charge the card" do
      expect(charge).to_not be_successful
    end
    it "raises a CardError from Stripe" do
      expect(charge.status).to eq(:error)
    end
    it "populates the error_messages method with error" do
      expect(charge.error_message).to eq("Your card was declined.")
    end
  end

  context "with card token set to nil" do
    let(:card_number) { "4000000000000002" }
    let(:charge)      { StripeWrapper::Charge.create(card: nil, amount: 999, description: "test") }

    it "does not successfully charge the card" do
      expect(charge).to_not be_successful
    end
    it "raises a CardError from Stripe" do
      expect(charge.status).to eq(:error)
    end
  end
end
