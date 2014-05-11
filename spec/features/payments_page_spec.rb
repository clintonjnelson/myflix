require 'spec_helper'

feature "Payments Page" do
    given(:joe) { Fabricate(:user) }
    given(:jen) { Fabricate(:admin, name: "Jen", email: "jen@example.com") }
    given!(:payment) {Fabricate(:payment, user: jen)}

  scenario "admin accesses payments page & views payments" do
    signin_user(jen)
    visit admin_payments_path
    expect(page).to have_content("$9.99")
    expect(page).to have_content("jen@example.com")
    expect(page).to have_content("Jen")
  end

  scenario "user attempts to access payments page but is denied access" do
    signin_user(joe)
    visit admin_payments_path
    expect(page).to have_content("You must be logged-in as an admin to do this.")
  end
end
