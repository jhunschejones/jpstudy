require "application_controller_test_case"

class SquareControllerTest < ApplicationControllerTestCase
  describe "#subscription_created" do
    describe "with valid signature" do
      setup do
        customers = mock()
        retrieve_customer_result = mock()
        retrieve_customer_result_data = mock()
        customer = { email_address: users(:carl).email }
        retrieve_customer_result_data.stubs(:customer).returns(customer)
        retrieve_customer_result.stubs(:error?).returns(false)
        retrieve_customer_result.stubs(:data).returns(retrieve_customer_result_data)
        customers.stubs(:retrieve_customer).returns(retrieve_customer_result)
        SQUARE_CLIENT.stubs(:customers).returns(customers)
      end

      teardown do
        SQUARE_CLIENT.unstub(:customers)
      end

      it "sends a subscription confirmation email" do
        assert_emails 1 do
          url = subscription_created_square_url
          body = { data: { object: { subscription: { customer_id: "1" } } } }
          post url, params: body, headers: { "X-Square-Signature" => valid_signature(url) }
        end
        last_email = ActionMailer::Base.deliveries.last
        assert_equal "Connect your jpstudy account", last_email.subject
        assert_equal [users(:carl).email], last_email.to
      end

      it "returns 200" do
        url = subscription_created_square_url
        body = { data: { object: { subscription: { customer_id: "1" } } } }
        post url, params: body, headers: { "X-Square-Signature" => valid_signature(url) }
        assert_response :ok
      end
    end

    describe "with invalid signature" do
      it "does not send a subscription confirmation email" do
        assert_no_emails do
          url = subscription_created_square_url
          body = { data: { object: { subscription: { customer_id: "1" } } } }
          post url, params: body, headers: { "X-Square-Signature" => "invalid" }
        end
      end

      it "returns 403" do
        url = subscription_created_square_url
        body = { data: { object: { subscription: { customer_id: "1" } } } }
        post url, params: body, headers: { "X-Square-Signature" => "invalid" }
        assert_response :forbidden
      end
    end
  end

  # We're not currently performing any actions in response to this webhook
  describe "#subscription_updated" do
    it "returns 200" do
      url = subscription_updated_square_url
      body = { data: { object: { subscription: { customer_id: "1" } } } }
      post url, params: body, headers: { "X-Square-Signature" => valid_signature(url) }
      assert_response :ok
    end
  end

  # Special redirect link for Square to send users after completing checkout
  describe "#logout" do
    it "logs out the user" do
      login(users(:carl))
      get logout_square_path
      assert_nil session[:session_token]
    end

    it "redirects to the login page with a message" do
      login(users(:carl))
      get logout_square_path
      follow_redirect!
      assert_equal login_path, path
      assert_equal "🙏 Thank you for subscribing! Please follow the link in your email to finalize your subscription.", flash[:success]
    end
  end

  def valid_signature(url)
    raw_post = "data[object][subscription][customer_id]=1"
    string_to_sign = "#{url}#{raw_post}"
    digest = OpenSSL::Digest.new("sha1")
    hmac = OpenSSL::HMAC.digest(digest, ENV.fetch("SQUARE_WEBHOOK_SIGNATURE_KEY"), string_to_sign)
    Base64.encode64(hmac).strip
  end
end
