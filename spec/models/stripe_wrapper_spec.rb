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
  let(:email) { 'joeuser@example.com' }
  let(:card_number) { "4242424242424242" }
  before { StripeWrapper.set_api_key }

  context "with valid card info" do
    it "makes a new customer in Stripe and returns the Customer info response" do
      customer = StripeWrapper::Customer.create(email: email, card: token)
      expect(customer).to be_successful
    end
  end

  context "with invalid card info" do
    it "does not make a new customer" do
      customer = StripeWrapper::Customer.create(email: email, card: " ")
      expect(customer).to_not be_successful
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

  context "with valid charge using customer reference" do
    let(:card_number) { "4242424242424242" }
    let(:customer) { StripeWrapper::Customer.create(email: email, card: token) }
    let(:charge) { StripeWrapper::Charge.create(customer: customer.response.id, amount: 999, description: "test") }

    it "successfully charges the card" do
      expect(charge).to be_successful
    end
    it "charges 999 to the customer's card" do
      expect(charge.response.amount).to eq(999)
    end
  end

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

  context "with invalid customer info" do
    let(:card_number) { "4242424242424242" }
    let(:charge) { StripeWrapper::Charge.create(customer: " ", amount: 999, description: "test") }

    it "does not successfully charge the card" do
      expect(charge).to_not be_successful
      #how do I verify that error prevents charge without error killing the test?
    end
    it "raises an InvalidRequestError from Stripe" do
      expect do
        StripeWrapper::Charge.create(customer: " ", amount: 999, description: "test")
      end.to raise_error Stripe::InvalidRequestError
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
  end

end
