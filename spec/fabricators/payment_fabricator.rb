Fabricator(:payment) do
  reference_id("#{ Faker::Number.number(10) }")
  amount 999
  user
end
