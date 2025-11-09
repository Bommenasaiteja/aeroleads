class OpenaiService
  def initialize
    @client = OpenAI::Client.new(
      access_token: ENV['OPENAI_API_KEY'] || Rails.application.credentials.dig(:openai, :api_key)
    )
  end

  def process_chat_command(message)
    system_prompt = build_system_prompt
    
    response = @client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: message }
        ],
        max_tokens: 500,
        temperature: 0.7
      }
    )

    content = response.dig("choices", 0, "message", "content")
    parse_ai_response(content, message)
  end

  def generate_blog_post(title, description = "")
    prompt = "Write a comprehensive blog post about '#{title}'. #{description.present? ? "Additional context: #{description}" : ""} 
    
    Please write an engaging, informative article that includes:
    - An engaging introduction
    - Main content with practical examples where applicable
    - Key takeaways or conclusion
    - Make it around 800-1200 words
    - Write in a professional yet accessible tone"

    response = @client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [
          { role: "system", content: "You are a professional technical writer who creates engaging and informative blog posts about programming and technology topics." },
          { role: "user", content: prompt }
        ],
        max_tokens: 2000,
        temperature: 0.8
      }
    )

    response.dig("choices", 0, "message", "content")
  end

  private

  def build_system_prompt
    phone_numbers_count = PhoneNumber.count
    pending_count = PhoneNumber.pending.count
    called_count = PhoneNumber.called.count
    
    "You are an AI assistant for an autodialer system. You can help with the following commands:
    
    Current Status:
    - Total phone numbers: #{phone_numbers_count}
    - Pending calls: #{pending_count}
    - Completed calls: #{called_count}
    
    Available Commands:
    1. 'call [phone_number]' - Make a call to a specific number
    2. 'call all' - Call all pending numbers
    3. 'show numbers' or 'list numbers' - Show all phone numbers
    4. 'show stats' or 'show statistics' - Show call statistics
    5. 'upload numbers' - Guide user to upload phone numbers
    
    Please respond with a JSON object containing:
    - action: one of ['call_single', 'call_all', 'show_numbers', 'show_stats', 'upload_guide', 'help', 'unknown']
    - parameters: relevant parameters (like phone number for call_single)
    - message: A friendly response to the user
    
    Be conversational and helpful!"
  end

  def parse_ai_response(content, original_message)
    begin
      # Try to extract JSON from the response
      json_match = content.match(/\{.*\}/m)
      if json_match
        parsed = JSON.parse(json_match[0])
        return {
          action: parsed['action'],
          parameters: parsed['parameters'] || {},
          message: parsed['message'] || content
        }
      end
    rescue JSON::ParserError
      # Fallback to simple parsing if JSON parsing fails
    end

    # Fallback parsing
    downcase_message = original_message.downcase
    
    if downcase_message.include?('call') && downcase_message.match(/\d{10,}/)
      phone_number = original_message.match(/(\d{10,})/)&.[](1)
      return {
        action: 'call_single',
        parameters: { phone_number: phone_number },
        message: "I'll initiate a call to #{phone_number}"
      }
    elsif downcase_message.include?('call all')
      return {
        action: 'call_all',
        parameters: {},
        message: "I'll start calling all pending numbers"
      }
    elsif downcase_message.include?('show') && (downcase_message.include?('number') || downcase_message.include?('list'))
      return {
        action: 'show_numbers',
        parameters: {},
        message: "Here are all the phone numbers in the system"
      }
    elsif downcase_message.include?('stat')
      return {
        action: 'show_stats',
        parameters: {},
        message: "Here are the current call statistics"
      }
    else
      return {
        action: 'help',
        parameters: {},
        message: content
      }
    end
  end
end