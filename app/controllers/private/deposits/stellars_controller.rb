module Private
  module Deposits
    class StellarsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end
