# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :payment, :class => 'Payments' do
    reference_id "MyString"
    user_id 1
    amount 999
  end
end
