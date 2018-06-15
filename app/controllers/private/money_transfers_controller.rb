module Private
	class MoneyTransfersController < BaseController
		before_action :set_money_transfer, only: [:show, :edit, :update, :destroy]
      before_action :set_balance, only:[:new, :create]
   def index
      @money_transfers = MoneyTransfer.all
   end
   def show
   end
   
   # GET /money_transfers/new
   def new
      # binding.pry
      country #get base @currency
      @fait_currencies = [] 
      Currency.all.each do |x|
         if !x.coin?
           @fait_currencies.push(x.code)
         end  
       end
      @money_transfer = MoneyTransfer.new
   end
   
   # GET /money_transfers/1/edit
   def edit
   end
   
   # POST /money_transfers
   # POST /money_transfers.json
   def create
      #implement transations query here 
      balance = @available_balance.to_d - money_transfer_params['amount_send'].to_d
      fee = money_transfer_params['amount_send'].to_d * 0.02 #fee 2%
      if balance-fee > 0
         @money_transfer = MoneyTransfer.new(money_transfer_params)
         @money_transfer.transfer_fee = fee
         @money_transfer.member_id = current_user.id
         respond_to do |format|
            if @money_transfer.save
               @admin.balance += fee
               @admin.save
               @current_user_account.balance -= (money_transfer_params['amount_send'].to_d + fee)
               @current_user_account.save
               reciver_member = Member.find_by_email(money_transfer_params['reciver_email'])
               if !reciver_member.nil?
                  @reciver_account = reciver_member.accounts.find_by_currency(Currency.find_by_code(money_transfer_params['reciver_currency_id']).id)
                  @reciver_account.balance += money_transfer_params['amount_recived'].to_d
                  @reciver_account.save
               else
                  #if member account does not exists then add money on admin account
                  admin = Member.find_by_email('pankaj@sgit.io').accounts.find_by_currency(Currency.find_by_code(money_transfer_params['reciver_currency_id']).id)
                  admin.balance += money_transfer_params['amount_recived'].to_d
                  admin.save
               end
               format.html { redirect_to @money_transfer, notice: 'MoneyTransfer was successfully created.' }
               format.json { render :show, status: :created, location: @money_transfer }
            else
               format.html { render :new }
               format.json { render json: @money_transfer.errors, status: :unprocessable_entity }
            end
         end
      else
         flash[:error] = "You do not have sufficent balance!"
         format.html { render :new }
         format.json { render json: @money_transfer.errors, status: :unprocessable_entity }
      end
      
   end
   
   # PATCH/PUT /money_transfers/1
   # PATCH/PUT /money_transfers/1.json
   def update
      respond_to do |format|
         if @money_transfer.update(money_transfer_params)
            format.html { redirect_to @money_transfer, notice: 'MoneyTransfer was successfully updated.' }
            format.json { render :show, status: :ok, location: @money_transfer }
         else
            format.html { render :edit }
            format.json { render json: @money_transfer.errors, status: :unprocessable_entity }
         end
      end
      
   end
   
   # DELETE /money_transfers/1
   # DELETE /money_transfers/1.json
   def destroy
      @money_transfer.destroy
         respond_to do |format|
         format.html { redirect_to money_transfers_url, notice: 'MoneyTransfer was successfully destroyed.' }
         format.json { head :no_content }
      end
   end
   
   private
   
   # Use callbacks to share common setup or constraints between actions.
   def set_balance
      @admin = Member.find_by_email('pankaj@sgit.io').accounts.find_by_currency(Currency.find_by_code(@currency).id)
      @current_user_account = current_user.accounts.find_by_currency(Currency.find_by_code(@currency).id) 
      @available_balance = @current_user_account.balance
   end

   def set_money_transfer
      @money_transfer = MoneyTransfer.find(params[:id])
   end
   
   # Never trust parameters from the scary internet, only allow the white list through.
   def money_transfer_params
      params.require(:money_transfer).permit(:amount_send, :amount_recived, :reciver_bank_account, :reciver_bank_ifsc, :reciver_name, :reciver_mobile, :reciver_email, :relationship_with_reciver, :tx_id, :reciver_bank_name, :reciver_bank_branch, :reciver_currency_id, :sender_currency_id)
   end
	end
end