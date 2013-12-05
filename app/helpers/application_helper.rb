module ApplicationHelper
  def feedback_address
    Maslow::Application.config.feedback_address
  end
end
