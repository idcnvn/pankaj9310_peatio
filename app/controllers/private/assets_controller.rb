module Private
  class AssetsController < BaseController
    skip_before_action :auth_member!, only: [:index]

    def index
      @cny_assets  = Currency.assets('cny')
      @inr_assets  = Currency.assets('inr')
      @btc_proof   = Proof.current :btc
      @cny_proof   = Proof.current :cny
      @inr_proof   = Proof.current :inr

      if current_user
        @btc_account = current_user.accounts.with_currency(:btc).first
        @cny_account = current_user.accounts.with_currency(:cny).first
        @inr_account = current_user.accounts.with_currency(:inr).first
      end
    end

    def partial_tree
      account    = current_user.accounts.with_currency(params[:id]).first
      @timestamp = Proof.with_currency(params[:id]).last.timestamp
      @json      = account.partial_tree.to_json.html_safe
      respond_to do |format|
        format.js
      end
    end

  end
end
