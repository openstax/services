require 'rails_helper'

module Newflow
  describe StudentSignup, type: :handler do
    context 'when success' do
      before(:all) do
        load('db/seeds.rb')
      end

      let(:result) do
        described_class.call(params: params)
      end

      let(:params) do
        {
          signup: {
            first_name: 'Bryan',
            last_name: 'Dimas',
            email: email,
            password: Faker::Internet.password(min_length: 8),
            terms_accepted: true,
            newsletter: true,
            contract_1_id: 1,
            contract_2_id: 2
          }
        }
      end

      let(:email) do
        Faker::Internet.free_email
      end

      it 'creates an (unverified) user with role = student' do
        expect { result }.to change { User.where(state: 'unverified', role: 'student').count }
      end

      it 'creates an identity' do
        expect { result }.to change { Identity.count }
      end

      it 'creates an authentication with provider = identity' do
        expect { result }.to change { Authentication.where(provider: 'identity').count }
      end

      it 'agrees to terms of use and privacy policy when contracts_required' do
        # TODO: ideally would do this but it fails with an error:
        # expect_any_instance_of(AgreeToTerms).to receive(:call).twice.and_call_original

        expect {
          described_class.call(params: params, contracts_required: true)
        }.to change {
          FinePrint::Signature.count
        }.by(2)
      end

      it 'doesnt agrees to terms of use and privacy policy when contracts NOT required' do
        # TODO: ideally would do this but it fails with an error:
        # expect_any_instance_of(AgreeToTerms).not_to receive(:call)

        expect {
          described_class.call(params: params, contracts_required: false)
        }.not_to change {
          FinePrint::Signature.count
        }
      end

      it 'creates an email address' do
        expect { result }.to change { EmailAddress.count }
      end

      it 'sends a confirmation email' do
        expect_any_instance_of(NewflowMailer).to(
          receive(:signup_email_confirmation).with(
            hash_including({ email_address: an_instance_of(EmailAddress) })
          )
        )
        result
      end

      context 'interacts with salesforce' do
        before(:each) do
          disable_sfdc_client
          allow(Settings::Salesforce).to receive(:push_leads_enabled) { true }
        end

        it 'uploads leads to salesforce' do
          expect_any_instance_of(PushSalesforceLead).to receive(:exec)
          result
        end

        it 'signs up user for the newsletter when checked' do
          expect_any_instance_of(PushSalesforceLead).to receive(:exec).with(hash_including({ newsletter: true }))
          result
        end

        it 'does NOT sign up user for the newsletter when NOT checked' do
          expect_any_instance_of(PushSalesforceLead).to receive(:exec).with(hash_including({ newsletter: false }))
          params[:signup][:newsletter] = false
          result
        end
      end
    end

    context 'failure because a user with the given email address already exists' do
      before do
        create_newflow_user(email)
      end

      let(:email) do
        Faker::Internet.free_email
      end

      let(:params) do
        {
          signup: {
            first_name: 'Bryan',
            last_name: 'Dimas',
            email: email,
            password: Faker::Internet.password(min_length: 8),
            terms_accepted: true,
            newsletter: true,
            contract_1_id: 1,
            contract_2_id: 2
          }
        }
      end

      let(:result) do
        described_class.call(params: params)
      end

      example do
        expect(result.errors).to have_offending_input(:email)
      end
    end

    describe 'failure because the domain provider is invalid' do
      before do
        EmailDomainMxValidator.strategy = EmailDomainMxValidator::FakeStrategy.new(expecting: false)
      end

      let(:params) do
        {
          signup: {
            first_name: 'Bryan',
            last_name: 'Dimas',
            email: 'user@baddomain.com',
            password: Faker::Internet.password(min_length: 8),
            terms_accepted: true,
            newsletter: true,
            contract_1_id: 1,
            contract_2_id: 2
          }
        }
      end

      example do
        result = described_class.call(params: params)
        expect(result.errors).to have_offending_input(:email)
      end
    end
  end
end