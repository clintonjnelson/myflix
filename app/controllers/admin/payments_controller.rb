class Admin::PaymentsController < AuthorizationController

  def index
    @payments = Payment.all
  end

  def create

  end
end
