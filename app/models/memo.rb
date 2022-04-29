class Memo < ApplicationRecord
  has_rich_text :content
  belongs_to :user, inverse_of: :memos
end
