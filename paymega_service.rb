# frozen_string_literal: true

class PaymegaService
  API_URL = 'https://api.paymega.io'

  class Client
    extend Dry::Initializer[undefined: false]

    param :username
    param :password
    option :url, default: proc { API_URL }
    option :connection, default: proc { build_connection }

    private

    def build_connection
      Faraday.new(@url) do |conn|
        conn.request :json
        conn.response :json, content_type: /\bjson$/
        conn.request :basic_auth, @username, @password
        conn.adapter Faraday.default_adapter
      end
    end
  end

  class Schema
    class << self
      def pay(attributes)
        schema = Dry::Schema.Params do
          required(:service).filled(:string)
          required(:currency).filled(:string, max_size?: 3)
          required(:amount).value(:decimal)
          optional(:customer).hash do
            required(:reference_id).value(:string)
          end
          # could be expanded here
        end

        schema.call(attributes)
      end

      def payout(attributes)
        schema = Dry::Schema.Params do
          required(:reference_id).filled(:string)
          required(:service).filled(:string)
          required(:currency).filled(:string, max_size?: 3)
          required(:amount).value(:decimal)
          required(:fields).hash
          # could be expanded here
        end

        schema.call(attributes)
      end
    end
  end

  class << self
    def parse_callback(body)
      JSON.parse(body).dig('data', 'status')
    end
  end

  def initialize(username:, password:)
    @connection = Client.new(username, password).connection
  end

  def pay(attributes:)
    validation = Schema.pay(attributes)
    return validation.errors.to_h if validation.failure?

    payload = {
      data: {
        type: 'payment-invoices',
        attributes: attributes
      }
    }.to_json

    @connection.post('/payment-invoices', payload)
  end

  def payout(attributes:)
    validation = Schema.payout(attributes)
    return validation.errors.to_h if validation.failure?

    payload = {
      data: {
        type: 'payout-invoice',
        attributes: attributes
      }
    }.to_json

    @connection.post('/payout-invoices', payload)
  end
end
