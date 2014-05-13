require 'spec_helper'

feature "User With Failed Credit Card Charge" do
  given(:joe) { Fabricate(:user, email: 'joe@example.com',
                                 name: 'joe',
                                 password: 'password',
                                 locked_account: true) }

  scenario "tries to sign in" do
    signin_user(joe)
    expect(page).to have_content "Your account is locked"
  end

  scenario "user changes card number & submits payment to unlock account"
end
