class Admin::Users::ActivationsController < Admin::BaseController
  before_action :set_user

  def create
    @user.update!(active: true)
    redirect_to admin_users_path, notice: "เปิดใช้งานบัญชี #{@user.name} แล้ว"
  end

  def destroy
    if @user.update(active: false)
      redirect_to admin_users_path, notice: "ระงับการใช้งานบัญชี #{@user.name} แล้ว"
    else
      redirect_to admin_users_path, alert: @user.errors.full_messages.to_sentence
    end
  end

  private
    def set_user
      @user = User.find(params[:user_id])
    end
end
