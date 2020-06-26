require 'rails_helper'

module Newflow
  RSpec.describe LoginController, type: :controller do
    describe 'GET #login_form' do
      example 'success' do
        get(:login_form)
        expect(response).to have_http_status(:success)
      end
    end

    describe 'POST #login' do
      describe 'success' do
        before do
          create_newflow_user('user@openstax.org', 'password')
          expect_any_instance_of(AuthenticateUser).to receive(:call).once.and_call_original
        end

        let(:params) do
          { login_form: { email: 'user@openstax.org', password: 'password' } }
        end

        it 'logs in the user' do
          expect_any_instance_of(described_class).to receive(:sign_in!).once.and_call_original
          post('login', params: params)
          expect(assigns(:current_user)).to eq(User.last)
        end

        it 'redirects on success' do
          post('login', params: params)
          expect(response).to have_http_status(:redirect)
        end

        it 'redirects back to `r`eturn parameter' do
          path = Faker::Internet.slug

          # GET login_form with `?r=URL` stores the url to return to after login
          get('login_form', params: { r: "https://openstax.org/#{path}" })

          post('login', params: params)
          expect(response).to redirect_to("https://openstax.org/#{path}")
        end

        it 'checks `r`eturn parameter is whitelisted' do
          expect(Host).to receive(:trusted?).once.and_call_original
          # GET login_form with `?r=URL` may store a SAFE url to return to after login
          get('login_form', params: { r: 'https://maliciousdomain.com' })

          post('login', params: params)
          expect(response).not_to redirect_to('https://maliciousdomain.com')
        end

        it 'creates a security log' do
          expect {
            post('login', params: params)
          }.to change {
            SecurityLog.where(event_type: :sign_in_successful).count
          }
        end
      end

      describe 'failure' do
        describe 'when cannot_find_user' do
          it 'creates a security log' do
            expect {
              post('login', params: { login_form: { email: 'noone@openstax.org', password: 'password' } })
            }.to change {
              SecurityLog.sign_in_failed.where(event_data: { reason: :cannot_find_user, user: nil}).count
            }
          end
        end

        describe 'when multiple_users' do
          before do
            user1 = create_user 'user1'
            email1 = create_email_address_for(user1, email_address)
            user2 = create_user 'user2'
            email2 = create_email_address_for(user2, 'user-2@example.com')
            ContactInfo.where(id: email2.id).update_all(value: email1.value)
          end

          let(:email_address) do
            'user@example.com'
          end

          it 'creates a security log' do
            expect {
              post('login', params: { login_form: { email: email_address, password: 'password' } })
            }.to change {
              SecurityLog.where(event_type: :sign_in_failed).count
            }
          end
        end

        describe 'when too_many_login_attempts' do
          before do
            stub_const 'RateLimiting::MAX_LOGIN_ATTEMPTS_PER_USER', max_attempts_per_user
          end

          let(:email) { FactoryBot.create(:email_address, user: user, verified: true) }
          let(:user) { FactoryBot.create(:user) }
          let(:max_attempts_per_user) { 0 }

          it 'creates a security log' do
            expect {
              post('login', params: { login_form: { email: email.value, password: 'wrongpassword' } })
            }.to change {
              SecurityLog.where(
                event_type: :sign_in_failed,
                event_data: {
                  reason: :too_many_login_attempts,
                  user: user
                }
              ).count
            }
          end
        end

        it 'saves the email to the session' do
          post('login', params: { login_form: { email: 'noone@openstax.org', password: 'wrongZpassword' } })
          expect(session[:login_failed_email]).to  eq('noone@openstax.org')
        end
      end
    end

    describe 'GET #logout' do
      it 'redirects to caller-specified URL if in whitelist' do
        get(:logout, params: { r: "https://something.openstax.org/howdy?blah=true" })
        expect(response).to redirect_to("https://something.openstax.org/howdy?blah=true")
      end

      it 'does not redirect to a caller-specified URL if not in whitelist' do
        get(:logout, params: { r: "http://www.google.com" })
        expect(response).to redirect_to("/")
      end
    end
  end
end