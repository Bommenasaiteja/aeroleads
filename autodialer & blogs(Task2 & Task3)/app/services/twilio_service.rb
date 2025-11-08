class TwilioService
  def initialize
    @client = Twilio::REST::Client.new(
      Rails.application.credentials.twilio[:account_sid],
      Rails.application.credentials.twilio[:auth_token]
    )
  end

  def make_call(to_number, phone_number_id, use_webhooks: false)
    # In development mode, simulate calls to avoid trial account limitations
    if Rails.env.development? && ENV['TWILIO_MOCK_MODE'] != 'false'
      return simulate_call(to_number, phone_number_id)
    end
    
    call_options = {
      to: to_number,
      from: Rails.application.credentials.twilio[:phone_number],
      twiml: generate_twiml_for_demo
    }
    
    # Add webhook options only if explicitly requested and in production/staging
    if use_webhooks && Rails.env.production?
      call_options.merge!(
        status_callback: Rails.application.routes.url_helpers.twilio_status_callback_url(phone_number_id: phone_number_id),
        status_callback_event: %w[initiated ringing answered completed],
        status_callback_method: 'POST'
      )
    end
    
    begin
      call = @client.calls.create(**call_options)
      
      # Log the call
      phone_number = PhoneNumber.find(phone_number_id)
      call_log = phone_number.call_logs.create!(
        call_sid: call.sid,
        status: 'initiated',
        started_at: Time.current
      )
      
      { success: true, call_sid: call.sid, call_log: call_log }
    rescue Twilio::REST::RestError => e
      Rails.logger.error "Twilio error: #{e.message}"
      { success: false, error: e.message }
    end
  end

  def get_call_status(call_sid)
    @client.calls(call_sid).fetch
  end

  private

  def simulate_call(to_number, phone_number_id)
    # Simulate a successful call for development
    fake_call_sid = "CAdev#{SecureRandom.hex(16)}"
    
    phone_number = PhoneNumber.find(phone_number_id)
    call_log = phone_number.call_logs.create!(
      call_sid: fake_call_sid,
      status: 'completed',
      started_at: Time.current,
      duration: rand(10..60) # Random duration between 10-60 seconds
    )
    
    # Update phone number status
    phone_number.update!(status: 'called')
    
    Rails.logger.info "SIMULATED CALL: to #{to_number}, call_sid: #{fake_call_sid}"
    
    { success: true, call_sid: fake_call_sid, call_log: call_log, simulated: true }
  end

  def generate_twiml_for_demo
    '<Response><Say voice="alice">Hello! This is a demo call from our autodialer system. This is just a test call for development purposes. Thank you!</Say><Pause length="2"/><Say voice="alice">Have a great day!</Say></Response>'
  end
end