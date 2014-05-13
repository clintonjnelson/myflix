require 'spec_helper'

describe "Stripe Event" do

  describe "charge.succeeded" do
    let!(:joe) { Fabricate(:user, stripe_customer_id: 'cus_3zLBfzAWn0rnYL') }
    before do
      stub_event 'evt_charge_succeeded' #See spec/support/macros.rb
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
    it "unlocks the users account if it is in a locked state" do
      joe.update_attribute(:locked_account, true)
      expect(User.last.locked_account).to be_true

      stub_event 'evt_charge_succeeded'
      post '/stripe_events', id: 'evt_charge_succeeded'
      expect(User.last.locked_account).to be_false
    end
  end

  describe "charge.failed" do
    let!(:joe) { Fabricate(:user, stripe_customer_id: 'cus_3zLBfzAWn0rnYL') }
    before do
      stub_event 'evt_charge_failed' #See spec/support/macros.rb
      post '/stripe_events', id: 'evt_charge_failed'
    end
    after { ActionMailer::Base.deliveries.clear }

    it "response status is 200-OK" do
      expect(response.code).to eq("200")
    end
    it "locks the users account" do
      expect(User.last.locked_account).to be_true
    end
    context "email notice" do
      it "sends an email to the user that the payment failed & account is locked" do
        expect(ActionMailer::Base.deliveries.count).to eq(1)
      end
      it "provides a link in the email to a page to pay the charge" do
        expect(ActionMailer::Base.deliveries.last.parts.first.body.raw_source).to include("MyFLiX Customer Service")
      end
    end
  end
end
