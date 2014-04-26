module StripeWrapper

  def self.set_api_key
    Stripe.api_key = (Rails.env.production? ? ENV['STRIPE_LIVE_SECRET_KEY'] : ENV['STRIPE_TEST_SECRET_KEY'])
  end

  class Customer
    attr_reader :response, :status
    def initialize(options={})
      @response = options[:response]
      @status = options[:status]
    end

    def self.create(options={})
      StripeWrapper.set_api_key
      begin
        response = Stripe::Customer.create(email: options[:email],
                                            card: options[:card])
        new(response: response, status: :success)
      rescue Stripe::InvalidRequestError => e
        new(response: e, status: :error)
      end
    end

    def successful?
      self.status == :success
    end

    def error_messages
      self.response.message
    end
  end


  class Charge
    attr_reader :response, :status
    def initialize(options={})
      @response = options[:response]
      @status = options[:status]
    end

    def self.create(options={})
      StripeWrapper.set_api_key
      begin
        if !options[:customer].nil?
          response = Stripe::Charge.create(customer: options[:customer],
                                           amount: options[:amount],
                                           description: options[:description],
                                           currency: 'usd')
        elsif !options[:card].nil?
          response = Stripe::Charge.create(card: options[:card],
                                           amount: options[:amount],
                                           description: options[:description],
                                           currency: 'usd')
        # Seems like need to protect this with an "else", but can't find reason with testing
        else
          raise "Invalid Card Number"
        end
        new(response: response, status: :success)
      rescue Stripe::CardError => e
        new(response: e, status: :error)
      rescue Stripe::InvalidRequestError => e
        new(response: e, status: :error)
      rescue RuntimeError => e
        new(response: e, status: :error)
      end
    end

    def successful?
      self.status == :success
    end

    def error_messages
      self.response.message
    end
  end
end
