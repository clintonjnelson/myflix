require 'spec_helper'

describe "Stripe Event" do
  def stub_event(fixture_id, status = 200)
    stub_request(:get, "https://api.stripe.com/v1/events/#{fixture_id}").
    to_return(status: status, body: File.read("spec/support/fixtures/#{fixture_id}.json"))
  end

  describe "charge.succeeded" do
    let!(:joe) { Fabricate(:user, stripe_customer_id: 'cus_3zLBfzAWn0rnYL') }
    before do
      stub_event 'evt_charge_succeeded'
      post '/stripe_events', id: 'evt_charge_succeeded'
    end

    it "response status is 200-OK" do
      expect(response.code).to eq('200')
    end
    it "makes a new Payment object in the payments table" do
      expect(Payment.count).to eq(1)
    end
    it "saves the stripe charge reference_id into the Payment" do
      expect(Payment.last.reference_id).to eq('ch_1040kq2MJ4vAOzhlvxK543Cs')
    end
    it "saves the user's user_id reference into the Payment" do
      expect(Payment.last.user_id).to eq(joe.id)
    end
    it "saves the charge amount into the Payment" do
      expect(Payment.last.amount).to eq(999)
    end
  end
end
