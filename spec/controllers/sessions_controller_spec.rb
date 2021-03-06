require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  let(:user) { create(:user) }
  describe ':new' do
    it 'render new template' do
      get :new
      expect(response).to render_template(:new)
    end
  end

  describe ':create' do
    it 'redirect to root_path' do
      post :create, params: { email: user.email, password: '888888' }
      expect(response).to redirect_to(root_path)
    end

    it 'redirect to new_session_path' do
      post :create, params: { email: user.email, password: '999999' }
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe ':destroy' do
    it 'redirect to root_path' do
      post :create, params: { email: user.email, password: '888888' }
      delete :destroy, params: { id: user.id }
      expect(response).to redirect_to(root_path)
    end
  end
end

# 模仿cucumber feature测试相当于浏览器行为
# feature 'user' do
#   background do
#     # User.create(email: "123@qq.com", password: "123456", password_confirmation: "123456")
#     FactoryGirl.create(:user)
#   end

#   context 'user login' do
#     scenario 'user login success' do
#       visit new_session_path
#       within('form') dor
#         fill_in 'email', with: 'email1@factory.com'
#         fill_in 'password', with: '888888'
#         click_button '登录'
#       end
#       expect(page).to have_content '退出'
#     end
#     # given(:other_user) { User.create(email: 'other@example.com', password: 'rous')}
#     given(:other_user) { FactoryGirl.create(:user) }

#     scenario 'user login failed' do
#       visit new_session_path
#       within('form') do
#         fill_in 'email', with: other_user.email
#         fill_in 'password', with: other_user.password
#         click_button '登录'
#       end
#       expect(page).to have_content '登录'
#     end
#   end
# end
