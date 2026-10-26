module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :authenticate

      rescue_from ActionController::ParameterMissing do |error|
        render_error :bad_request, "parameter_missing", error.message
      end

      rescue_from ActiveRecord::RecordNotFound do |error|
        render_error :not_found, "not_found", error.message
      end

      rescue_from ActiveRecord::RecordInvalid do |error|
        render_error :unprocessable_content, "validation_failed", error.record.errors.full_messages.to_sentence,
          details: error.record.errors.to_hash
      end

      rescue_from Stock::Error do |error|
        render_error :unprocessable_content, error.class.name.demodulize.underscore, error.message
      end

      rescue_from Stock::InsufficientStock do |error|
        render_error :unprocessable_content, "insufficient_stock", error.message,
          details: { requested: error.requested, available: error.available }
      end

      def route_not_found
        render_error :not_found, "not_found", "No route matches #{request.method} #{request.path}"
      end

      private
        attr_reader :current_user

        def authenticate
          @current_user = authenticate_with_http_token { |token, _options| ApiToken.authenticate(token)&.user }
          return if @current_user

          response.headers["WWW-Authenticate"] = 'Bearer realm="Stockroom"'
          render_error :unauthorized, "unauthorized", "A valid API token is required"
        end

        def render_error(status, code, message, details: nil)
          render json: { error: { code: code, message: message, details: details }.compact }, status: status
        end
    end
  end
end
