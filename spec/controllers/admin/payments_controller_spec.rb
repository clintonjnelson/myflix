require 'spec_helper'

describe Admin::PaymentsController do

  describe 'GET index' do
    let(:joe) {Fabricate(:admin)}
    before do
      sign_in_admin(joe)
      51.times { Fabricate(:payment, user: joe) }
      get :index
    end

    it "assigns the most recent payments to the @payments variables" do
      expect(assigns(:payments)).to be_present
    end
    it "includes the most recent payments" do
      another_payment = Fabricate(:payment, user: joe)
      expect(assigns(:payments)).to include(another_payment)
    end
    it "renders the admin payments index template" do
      expect(response).to render_template 'index'
    end
  end
end
