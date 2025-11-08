class TwilioWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token # Twilio webhooks don't include CSRF tokens
  
  def status_callback
    phone_number_id = params[:phone_number_id]
    call_sid = params[:CallSid]
    call_status = params[:CallStatus]
    call_duration = params[:CallDuration]
    
    Rails.logger.info "Twilio webhook: #{call_sid} - #{call_status} for phone_number_id: #{phone_number_id}"
    
    begin
      phone_number = PhoneNumber.find(phone_number_id)
      call_log = phone_number.call_logs.find_by(call_sid: call_sid)
      
      if call_log
        call_log.update!(
          status: call_status.downcase,
          duration: call_duration.to_i,
          ended_at: (call_status == 'completed' ? Time.current : nil)
        )
        
        # Update phone number status based on call result
        case call_status.downcase
        when 'completed', 'answered'
          phone_number.update(status: 'called')
        when 'busy', 'no-answer', 'failed'
          phone_number.update(status: 'failed')
        end
        
        Rails.logger.info "Updated call log #{call_log.id} with status: #{call_status}"
      else
        Rails.logger.warn "Call log not found for SID: #{call_sid}"
      end
      
      render xml: '<Response></Response>'
    rescue => e
      Rails.logger.error "Webhook error: #{e.message}"
      render xml: '<Response></Response>', status: 500
    end
  end
end
