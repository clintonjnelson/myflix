class Payment < ActiveRecord::Base
belongs_to :user

validates :reference_id, presence: true
validates :user_id, presence: true
end
