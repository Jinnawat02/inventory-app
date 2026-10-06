module Authorization
  extend ActiveSupport::Concern

  private
    def require_admin
      redirect_to root_path, alert: "ไม่มีสิทธิ์เข้าถึง" unless Current.user&.admin?
    end
end
