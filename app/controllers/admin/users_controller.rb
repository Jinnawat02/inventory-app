class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: %i[edit update]

  def index
    @users = User.order(:name)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to admin_users_path, notice: "สร้างผู้ใช้เรียบร้อยแล้ว"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to admin_users_path, notice: "บันทึกข้อมูลผู้ใช้เรียบร้อยแล้ว"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.expect(user: %i[name email_address role password password_confirmation])
    end
end
