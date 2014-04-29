require 'spec_helper'
require 'webmock/rspec'

describe UsersController do
  # Sidekiq::Testing.fake! do
  #   describe "Sidekiq" do
  #     before { post :create, params }
  #     after  do
  #       Sidekiq::Worker.clear_all
  #     end

  #     it "successfully sends to Sidekiq's queue" do
  #       expect(Sidekiq::Extensions::DelayedMailer.jobs.size).to eq(1)
  #     end
  #   end
  # end

  describe 'Registration' do

    describe "GET new" do
      it "makes a new instance" do
        get :new
        expect(assigns(:user)).to be_a_new User
      end
    end

    describe "GET new_with_token" do

      context "with valid token" do
        let(:joe) { Fabricate(:user) }
        let(:invite) { Fabricate(:invitation, inviter_id: joe.id) }
        before { get :new_with_token, token: invite.token }

        it "renders the 'new' view template" do
          expect(response).to render_template 'new'
        end
        it "makes a new instance of a user" do
          expect(assigns(:user)).to be_a_new User
        end
        it "populates the @invitation with the invite info to this user" do
          expect(assigns(:invitation)).to be_a Invitation
        end
        it "gets the invited guest's email from the token" do
          expect(assigns(:invitation).friend_email).to eq(invite.friend_email)
        end
      end

      context "with invalid token do" do
        before { get :new_with_token, token: "expired_token" }

        it "redirects to the expired token page for expired tokens" do
          expect(response).to redirect_to expired_token_path
        end
      end
    end

    describe "POST create" do

      context "with suggessful registration" do
        let(:joe)     { Fabricate(:user) }
        let(:params)  { {user: { name: joe.name, email: joe.email, password: joe.password }, stripeToken: "123", token: "abc" } }
        before do
          UserRegistration.any_instance.should_receive(:register_new_user).and_return(joe)
        end
        it "assigns the invitation token into an instance variable @invitation_token" do
          post :create, params
          expect(assigns(:invitation_token)).to eq("abc")
        end
        it "assigns the pre-user instance into an instance variable @user" do
          post :create, params
          expect(assigns(:user)).to be_a_new User
        end
        it "assigns the new user into the an instance variable @creation" do
          post :create, params
          expect(assigns(:creation)).to eq(joe)
        end
        it "flashes the error message" do
          post :create, params
          expect(flash[:notice]).to be_present
        end
        it "signs in user" do
          post :create, params
          expect(session[:user_id]).to eq(User.find_by(email: joe.email).id)
        end
      end

      context "with UNsuggessful registration" do
        let(:joe)     { Fabricate(:user) }
        let(:params)  { {user: { name: joe.name, email: joe.email, password: joe.password }, stripeToken: "123" } }
        before do
          UserRegistration.any_instance.should_receive(:register_new_user).and_return("Please fix the error.")
        end

        it "assigns the errors into the an instance variable @creation" do
          post :create, params
          expect(assigns(:creation)).to eq("Please fix the error.")
        end
        it "renders the new view template" do
          post :create, params
          expect(response).to render_template :new
        end
        it "flashes the error message" do
          post :create, params
          expect(flash[:error]).to be_present
        end
      end
    end
  end

  describe "GET show" do
    let!(:joe) { Fabricate(:user) }

    it "should set the @user with user for profile page" do
      sign_in_user
      get :show, id: joe.id
      expect(assigns(:user)).to eq(joe)
    end

    context "should should redirect unauthenticated/guest (not signed-in) users" do
      it_behaves_like "require_signed_in" do
        let(:verb_action) { get :show, id: joe.id }
      end
    end
  end


  describe "set_user" do
    let!(:joe) { Fabricate(:user) }

    it "should det the @user with user for profile page" do
      get :show, id: joe.id
      expect(@controller.instance_eval{set_user}).to eq(joe)
    end
  end
end


