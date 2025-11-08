class AiChatController < ApplicationController
  def process_message
    message = params[:message]
    
    if message.blank?
      render json: { success: false, message: "Please enter a message" }
      return
    end

    begin
      openai_service = OpenaiService.new
      response = openai_service.process_chat_command(message)
      
      case response[:action]
      when 'call_single'
        handle_single_call(response[:parameters]['phone_number'], response[:message])
      when 'call_all'
        handle_call_all(response[:message])
      when 'show_numbers'
        handle_show_numbers(response[:message])
      when 'show_stats'
        handle_show_stats(response[:message])
      when 'upload_guide'
        render json: {
          success: true,
          message: response[:message],
          action: 'redirect',
          url: upload_phone_numbers_path
        }
      else
        render json: {
          success: true,
          message: response[:message]
        }
      end
    rescue => e
      Rails.logger.error "AI Chat Error: #{e.message}"
      render json: {
        success: false,
        message: "Sorry, I encountered an error. Please try again."
      }
    end
  end

  private

  def handle_single_call(phone_number, ai_message)
    if phone_number.blank?
      render json: { success: false, message: "Please specify a valid phone number" }
      return
    end

    # Find or create the phone number
    phone_record = PhoneNumber.find_by(number: phone_number)
    unless phone_record
      phone_record = PhoneNumber.create(
        number: phone_number,
        name: "AI Added Number",
        status: 'pending',
        uploaded_at: Time.current
      )
    end

    # Make the call
    twilio_service = TwilioService.new
    result = twilio_service.make_call(phone_number, phone_record.id)
    
    if result[:success]
      phone_record.update(status: 'called')
      render json: {
        success: true,
        message: "✅ Call initiated to #{phone_number}! Call SID: #{result[:call_sid]}"
      }
    else
      render json: {
        success: false,
        message: "❌ Failed to make call: #{result[:error]}"
      }
    end
  end

  def handle_call_all(ai_message)
    pending_numbers = PhoneNumber.pending.limit(5) # Limit for demo
    
    if pending_numbers.empty?
      render json: {
        success: true,
        message: "No pending numbers to call. Please upload some phone numbers first."
      }
      return
    end

    twilio_service = TwilioService.new
    successful_calls = 0
    
    pending_numbers.each do |phone_number|
      result = twilio_service.make_call(phone_number.number, phone_number.id)
      if result[:success]
        phone_number.update(status: 'called')
        successful_calls += 1
      end
      sleep(1) # Rate limiting
    end
    
    render json: {
      success: true,
      message: "📞 Initiated #{successful_calls} calls out of #{pending_numbers.count} pending numbers!"
    }
  end

  def handle_show_numbers(ai_message)
    numbers = PhoneNumber.limit(10).pluck(:number, :status)
    numbers_list = numbers.map { |num, status| "#{num} (#{status})" }.join("\n")
    
    render json: {
      success: true,
      message: "📋 Here are your phone numbers:\n\n#{numbers_list}\n\nShowing first 10 numbers. View all at the Phone Numbers page."
    }
  end

  def handle_show_stats(ai_message)
    total = PhoneNumber.count
    pending = PhoneNumber.pending.count
    called = PhoneNumber.called.count
    successful_calls = CallLog.successful.count
    failed_calls = CallLog.failed.count
    
    stats_message = """📊 **Call Statistics:**
    
Total Numbers: #{total}
Pending Calls: #{pending}
Numbers Called: #{called}
Successful Calls: #{successful_calls}
Failed Calls: #{failed_calls}

Success Rate: #{total > 0 ? (successful_calls.to_f / total * 100).round(1) : 0}%"""
    
    render json: {
      success: true,
      message: stats_message
    }
  end
end
