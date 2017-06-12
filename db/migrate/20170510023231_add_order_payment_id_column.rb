# frozen_string_literal: true

class AddOrderPaymentIdColumn < ActiveRecord::Migration[5.0]
  def change
    add_column :orders, :payment_id, :integer
    add_column :orders, :status, :string, default: 'initial'

    add_index :orders, [:payment]
  end
end
