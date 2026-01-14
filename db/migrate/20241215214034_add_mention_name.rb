# frozen_string_literal: true

class AddMentionName < ActiveRecord::Migration[7.2]
  def change
    add_column :mentions, :name, :string, null: true, default: nil
  end
end
