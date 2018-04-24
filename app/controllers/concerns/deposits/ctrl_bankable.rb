module Deposits
  module CtrlBankable
    extend ActiveSupport::Concern
    
    included do
      before_filter :fetch
      protect_from_forgery with: :null_session
      skip_before_action :fetch, :only => [:hook]
      skip_before_action :auth_member!, :only => [:hook]
      skip_before_action :authenticate_token!, :only => [:hook]
      skip_before_action :verify_authenticity_token, :only => [:hook]
      skip_before_action :auth_verified!, :only => [:hook]
      skip_before_action :auth_activated!, :only =>[:hook]
    end

    def create
      @deposit = model_kls.new(deposit_params)
      if @deposit.save
        render text: @deposit.paypal_url(hook_url(@deposit)), status: 200
      else
        render text: @deposit.errors.full_messages.join, status: 403
      end
    end
    
    def destroy
      @deposit = current_user.deposits.find(params[:id])
      @deposit.cancel!
      render nothing: true
    end

    
    def hook
      params.permit! # Permit all Paypal input params
      status = params[:payment_status]
      @deposit = Deposit.find params[:invoice]
      if status == "Pending"
        @deposit.update_attributes confirmations: status, txid: params[:txn_id], done_at: Time.now
      elsif status == "Completed"
        @deposit.charge!(params[:txid])
        @deposit.update_attributes aasm_state: 'accepted', confirmations: status, txid: params[:txn_id], done_at: Time.now
      end
      redirect_to root_path()
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
