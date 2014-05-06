Fabricator(:payment) do
  reference_id("#{ Faker::Number.number(10) }")
  user
end
