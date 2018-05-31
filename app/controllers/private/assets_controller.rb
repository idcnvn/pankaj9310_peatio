module Private
  class AssetsController < BaseController
    skip_before_action :auth_member!, only: [:index]

    def index
      @cny_assets  = Currency.assets('cny')
      @inr_assets  = Currency.assets('inr')
      @usd_assets  = Currency.assets('usd')
      @aud_assets  = Currency.assets('aud')
      @btc_proof   = Proof.current :btc
      @xrp_proof   = Proof.current :xrp
      @ltc_proof   = Proof.current :ltc
      @xlm_proof   = Proof.current :xlm
      @cny_proof   = Proof.current :cny
      @inr_proof   = Proof.current :inr
      @usd_proof   = Proof.current :usd
      @aud_proof   = Proof.current :aud

      if current_user
        @btc_account = current_user.accounts.with_currency(:btc).first
        @xrp_account = current_user.accounts.with_currency(:xrp).first
        @xlm_account = current_user.accounts.with_currency(:xlm).first
        @ltc_account = current_user.accounts.with_currency(:ltc).first
        @cny_account = current_user.accounts.with_currency(:cny).first
        @inr_account = current_user.accounts.with_currency(:inr).first
        @aud_account = current_user.accounts.with_currency(:aud).first
        @usd_account = current_user.accounts.with_currency(:usd).first
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
