require 'spec_helper'

feature "user signs up and pays with credit card", { js: true, vcr: true } do

  background do
    visit register_path
    page.should have_content "Register"
  end

  scenario "with invalid user email & valid card info" do
    user_fills_form_and_submits(email: "")
    registration_requires_user_error_fixes

    user_fills_form_and_submits(email: "example.com")
    registration_requires_user_error_fixes(hidden=true)
  end
  scenario "with invalid password & valid card info" do
    user_fills_form_and_submits(password: "")
    registration_requires_user_error_fixes

    user_fills_form_and_submits(password: "yo")
    registration_requires_user_error_fixes
  end
  scenario "with invalid password & valid card info" do
    user_fills_form_and_submits(full_name: "")
    registration_requires_user_error_fixes
  end
  scenario "with valid user info & invalid card info" do
    user_fills_form_and_submits(card_number: '4242424242424241')
    registration_requires_card_error_fixes('card number is incorrect')

    user_fills_form_and_submits(cvc: '22')
    registration_requires_card_error_fixes('security code is invalid')
  end
  scenario "with valid user info & declined card" do
    user_fills_form_and_submits(card_number: '4000000000000069')
    registration_requires_card_error_fixes('Your card has expired.', true)
  end
  scenario "with all information correct" do
    user_fills_form_and_submits
    registration_and_payment_are_successful
  end
end



def registration_and_payment_are_successful
  page.should have_content "Welcome, joe"
end

def registration_requires_user_error_fixes(hidden=nil)
  page.should have_css('.help-block', ('minimum' || 'be' || "can't")) unless hidden
  page.should have_content "Register"
end

def registration_requires_card_error_fixes(error=nil, skip=nil)
  page.should have_css '.payment-errors' unless skip
  page.should have_content "#{error}" if error
  page.should have_content "Register"
end

def user_fills_form_and_submits(options={})
  # Default fill_in data:
  options[:email]       = 'joe@example.com'   unless options[:email]
  options[:password]    = 'password'          unless options[:password]
  options[:full_name]   = 'joe'               unless options[:full_name]
  options[:card_number] = '4242424242424242'  unless options[:card_number]
  options[:cvc]         = '333'               unless options[:cvc]
  options[:month]       = '7 - July'          unless options[:month]
  options[:year]        = '2017'              unless options[:year]

  fill_in 'Email Address',        with: options[:email]
  fill_in 'Password',             with: options[:password]
  fill_in 'Full Name',            with: options[:full_name]
  fill_in 'Credit Card Number',   with: options[:card_number]
  fill_in 'Security Code',        with: options[:cvc]
  select  options[:month],        from: 'date_month'
  select  options[:year],         from: 'date_year'
  click_button 'Sign Up'
end
