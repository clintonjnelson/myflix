module StripeWrapper

  def self.set_api_key
    Stripe.api_key = (Rails.env.production? ? ENV['STRIPE_LIVE_SECRET_KEY'] : ENV['STRIPE_TEST_SECRET_KEY'])
  end

  class Charge
    attr_reader :response, :error_message, :status
    def initialize(options={})
      @response = options[:response]
      @status = options[:status]
      @error_message = options[:error_message]
    end

    def self.create(options={})
      StripeWrapper.set_api_key
      begin
        response = Stripe::Charge.create(card: options[:card],
                                         customer: options[:customer],
                                         amount: options[:amount],
                                         description: options[:description],
                                         currency: 'usd')
        new(response: response, status: :success)
      rescue Stripe::CardError => e
        new(error_message: e.message, status: :error)
      rescue Stripe::InvalidRequestError => e
        new(error_message: e.message, status: :error)
      rescue RuntimeError => e
        new(error_message: e.message, status: :error)
      end
    end

    def successful?
      self.status == :success
    end
  end


  class Customer
    attr_reader :response, :error_message, :status
    def initialize(options={})
      @response = options[:response]
      @status = options[:status]
      @error_message = options[:error_message]
    end

    def self.create(options={})
      begin
        response = Stripe::Customer.create(card:  options[:card],
                                           plan:  options[:plan],
                                           email: options[:user].email)
        new(response: response, status: :success)
      rescue Stripe::InvalidRequestError => e
        new(error_message: e.message, status: :error)
      rescue Stripe::CardError => e
        new(error_message: e.message, status: :error)
      end
    end

    def successful?
      self.status == :success
    end
  end
end
