require 'spec_helper'

describe UserRegistration do
  let(:jen)         { Fabricate(:user) }
  let(:joe)         { Fabricate.build(:user) }
  let(:stripeToken) { '123abc' }
  let(:amount)      { 555 }
  let(:inviteToken) { nil }

  context "with valid user, card info, AND invitation", vcr: true do
    before do
      charge = double(:charge, successful?: true)
      StripeWrapper::Charge.should_receive(:create).and_return(charge)
    end
    after  { ActionMailer::Base.deliveries.clear }

    it "makes a new user" do
      UserRegistration.new(joe).register_new_user(stripeToken, amount, inviteToken)
      expect(User.count).to eq(1)
    end
    it "sets the inviter as following the friend" do
      invite = Fabricate(:invitation, inviter_id: jen.id)
      UserRegistration.new(joe).register_new_user(stripeToken, amount, invite.token)
      joe = User.last
      expect(jen.leaders).to include(joe)
    end
    it "sets the inviter as following the friend" do
      invite = Fabricate(:invitation, inviter_id: jen.id)
      UserRegistration.new(joe).register_new_user(stripeToken, amount, invite.token)
      joe = User.last
      expect(joe.leaders).to include(jen)
    end
    it "sets the invitation token to nil - thus invalidating it from use" do
      invite = Fabricate(:invitation, inviter_id: jen.id)
      UserRegistration.new(joe).register_new_user(stripeToken, amount, invite.token)
      expect(invite.reload.token).to be_nil
    end

    context "email sending" do
      before { UserRegistration.new(joe).register_new_user(stripeToken, amount, inviteToken) }
      after do
        ActionMailer::Base.deliveries.clear
        Sidekiq::Worker.clear_all
      end

      it "sends an email upon successful creation" do
        ActionMailer::Base.deliveries.should_not be_empty
      end
      it "sends email to the registering user's email address" do
        email = ActionMailer::Base.deliveries.last
        email.to.should eq([joe.email])
      end
      it "has a welcome message in the subject" do
        email = ActionMailer::Base.deliveries.last
        email.subject.should include("Welcome to MyFLiX")
      end
      it "has a welcome message in the body" do
        email = ActionMailer::Base.deliveries.last
        expect(email.parts.first.body.raw_source).to include(joe.name)
      end
      it "successfully sends to Sidekiq's queue"# do
      #   expect(Sidekiq::Extensions::DelayedMailer.jobs.size).to eq(1)
      # end
    end
  end

  context "with valid user and invalid credit card info" do
    before do
      charge = double(:charge, successful?: false, error_messages: "Card declined.")
      StripeWrapper::Charge.should_receive(:create).and_return(charge)
    end
    after do
      ActionMailer::Base.deliveries.clear
      Sidekiq::Worker.clear_all
    end

    it "does not create a new user" do
      UserRegistration.new(joe).register_new_user(stripeToken, amount, inviteToken)
      expect(User.count).to eq(0)
    end
    it "does not send an email" do
      UserRegistration.new(joe).register_new_user(stripeToken, amount, inviteToken)
      ActionMailer::Base.deliveries.should be_empty
    end
    it "returns the card error" do
      response = UserRegistration.new(joe).register_new_user(stripeToken, amount, inviteToken)
      expect(response).to eq("Card declined.")
    end
  end

  context "with invalid user and valid credit card info" do
    let(:invalid_joe) { Fabricate.build(:user, email: "") }
    before do
      charge = double(:charge, successful?: true)
      StripeWrapper::Charge.stub(:create).and_return(charge)
    end
    after  { ActionMailer::Base.deliveries.clear }

    it "does not create a new user" do
      UserRegistration.new(invalid_joe).register_new_user(stripeToken, amount, inviteToken)
      expect(User.count).to eq(0)
    end
    it "does not send an email" do
      MyflixMailer.should_not_receive(:welcome_email)
      UserRegistration.new(invalid_joe).register_new_user(stripeToken, amount, inviteToken)
      ActionMailer::Base.deliveries.should be_empty
    end
    it "returns the user error" do
      response = UserRegistration.new(invalid_joe).register_new_user(stripeToken, amount, inviteToken)
      expect(response).to eq(["Email can't be blank"])
    end
    it "does not try to charge the credit card" do
      StripeWrapper::Charge.should_not_receive(:create)
      UserRegistration.new(invalid_joe).register_new_user(stripeToken, amount, inviteToken)
    end
  end
end
