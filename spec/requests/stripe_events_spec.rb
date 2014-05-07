require 'spec_helper'

describe "Stripe Event" do

  describe "Successful Payment" do
    let(:charge_success) { charge_successful_event }
    before do
      Stripe.api_key = ENV['STRIPE_TEST_SECRET_KEY']
    end

    it "loads the response data into the StripeEvent"
    it "makes a new Payment object in the database" do
      post "/stripe_events", charge_success
      expect(Payment.count).to eq(1)
    end
    # it "saves the stripe charge reference_id into the Payment"
    # it "saves the user_id reference into the Payment"
    # it "saves the charge amount into the Payment"
  end
end

def charge_successful_event
  response = {
    "id" => "evt_103zLB2MJ4vAOzhlPH0i9Uc8",
    "created" => 1399436287,
    "livemode" => false,
    "type" => "charge.succeeded",
    "data" => {
      "object" => {
        "id" => "ch_103zLB2MJ4vAOzhlfwkt8QG5",
        "object" => "charge",
        "created" => 1399436287,
        "livemode" => false,
        "paid" => true,
        "amount" => 999,
        "currency" => "usd",
        "refunded" => false,
        "card" => {
          "id" => "card_103zLB2MJ4vAOzhlcrlEnN5P",
          "object" => "card",
          "last4" => "4242",
          "type" => "Visa",
          "exp_month" => 5,
          "exp_year" => 2014,
          "fingerprint" => "1vn304fKHbHgJdVt",
          "customer" => "cus_3zLBfzAWn0rnYL",
          "country" => "US",
          "name" => nil,
          "address_line1" => nil,
          "address_line2" => nil,
          "address_city" => nil,
          "address_state" => nil,
          "address_zip" => nil,
          "address_country" => nil,
          "cvc_check" => "pass",
          "address_line1_check" => nil,
          "address_zip_check" => nil
        },
        "captured" => true,
        "refunds" => [],
        "balance_transaction" => "txn_103zLB2MJ4vAOzhlHYj5yuXl",
        "failure_message" => nil,
        "failure_code" => nil,
        "amount_refunded" => 0,
        "customer" => "cus_3zLBfzAWn0rnYL",
        "invoice" => "in_103zLB2MJ4vAOzhlT6PJfbog",
        "description" => nil,
        "dispute" => nil,
        "metadata" => {},
        "statement_description" => "MyFlix BasePlan"
      }
    },
    "object" => "event",
    "pending_webhooks" => 1,
    "request" => "iar_3zLBZN21sv3OBi"
    }
end
