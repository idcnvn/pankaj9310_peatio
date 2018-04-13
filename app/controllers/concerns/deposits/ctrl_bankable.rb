module Deposits
  module CtrlBankable
    extend ActiveSupport::Concern

    included do
      before_filter :fetch
    end

    def create
      @deposit = model_kls.new(deposit_params)
      if @deposit.save
        redirect_to @deposit.paypal_url(deposits_banks_hook_url(@deposit)) and return
        # render nothing: true
      else
        render text: @deposit.errors.full_messages.join, status: 403
      end
    end

    def destroy
      @deposit = current_user.deposits.find(params[:id])
      @deposit.cancel!
      render nothing: true
    end

    # protect_from_forgery with: :null_session
    def hook
      binding.pry
      params.permit! # Permit all Paypal input params
      status = params[:payment_status]
      if status == "Completed"
        @deposit = Deposit.find params[:invoice]
        puts @deposit
        @deposit.update_attributes notification_params: params, status: status, transaction_id: params[:txn_id], purchased_at: Time.now
      end
      render nothing: true
    end

    private

    def fetch
      @account = current_user.get_account(params[:deposit][:currency])
      @model = model_kls
      @fund_sources = current_user.fund_sources.with_currency(params[:deposit][:currency])
      @assets = model_kls.where(member: current_user).order(:id).reverse_order.limit(10)
    end

    def deposit_params
      params[:deposit][:member_id] = current_user.id
      params[:deposit][:account_id] = @account.id
      params.require(:deposit).permit(:fund_source, :amount, :currency, :account_id, :member_id)
    end
  end
end
