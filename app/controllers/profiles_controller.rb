class ProfilesController < ApplicationController
  MINIMUM_PASSWORD_LENGTH = 8

  before_action :set_user

  def show
  end

  def edit
  end

  def update
    current_password_valid = @user.authenticate(params.dig(:user, :current_password).to_s)
    @user.assign_attributes(profile_params)
    @user.validate
    verify_password_change(current_password_valid) if changing_password?

    if @user.errors.none? && @user.save
      terminate_other_sessions if changing_password?
      redirect_to profile_path, notice: "บันทึกข้อมูลส่วนตัวเรียบร้อยแล้ว"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_user
      @user = Current.user
    end

    def profile_params
      params.expect(user: %i[name password password_confirmation])
    end

    def changing_password?
      profile_params[:password].present?
    end

    def verify_password_change(current_password_valid)
      @user.errors.add(:base, "รหัสผ่านปัจจุบันไม่ถูกต้อง") unless current_password_valid
      @user.errors.add(:password, :too_short, count: MINIMUM_PASSWORD_LENGTH) if profile_params[:password].length < MINIMUM_PASSWORD_LENGTH
    end

    def terminate_other_sessions
      @user.sessions.where.not(id: Current.session.id).destroy_all
    end
end
