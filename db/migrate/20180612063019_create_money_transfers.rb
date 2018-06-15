class CreateMoneyTransfers < ActiveRecord::Migration
  def change
    create_table :money_transfers do |t|
      t.string :amount_send
      t.string :amount_recived
      t.string :reciver_bank_name
      t.string :reciver_bank_branch
      t.string :reciver_bank_account
      t.string :reciver_name
      t.string :reciver_bank_ifsc
      t.string :reciver_mobile
      t.string :reciver_email
      t.string :tx_id
      t.string :relationship_with_reciver
      t.string :transfer_mode, default: 'wallet'
      t.string :sender_currency_id
      t.string :reciver_currency_id
      t.string :transfer_fee
      t.references :member, index: true
      t.references :source, polymorphic: true, index: true
      t.timestamps
    end
  end

end
