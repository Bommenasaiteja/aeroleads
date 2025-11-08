# Autodialer Setup Guide

## Prerequisites

1. Ruby 3.0+ and Rails 7.1+
2. Twilio Account with Phone Number
3. OpenAI API Key

## Environment Setup

### 1. Install Dependencies

```bash
bundle install
```

### 2. Configure API Keys

Run this command to set up your API credentials:

```bash
EDITOR=nano rails credentials:edit
```

Add the following configuration:

```yaml
twilio:
  account_sid: "your_twilio_account_sid"
  auth_token: "your_twilio_auth_token"
  phone_number: "+1234567890"  # Your Twilio phone number

openai:
  api_key: "sk-your-openai-api-key"
```

### 3. Database Setup

```bash
rails db:create
rails db:migrate
```

### 4. Start the Server

```bash
rails server
```

Visit `http://localhost:3000` to access the application.

## Features

### 📞 Autodialer
- Upload phone numbers via text or CSV
- Make individual calls or bulk calls
- Real-time call status tracking
- Call logs and statistics

### 🤖 AI Chat Interface
- Natural language commands
- "Call 1800-123-4567"
- "Call all numbers"
- "Show me the stats"
- "List all numbers"

### 📝 AI Blog Generation
- Generate blog posts using AI
- Provide titles with optional descriptions
- Automatic content generation
- Blog management system

## Testing with Safe Numbers

For testing, use:
- 1-800 numbers (toll-free)
- Test numbers like +15005550006 (Twilio test number)
- Your own phone numbers

**⚠️ Important: Never call real people without their consent!**

## Development Features

- Bootstrap UI with responsive design
- Real-time call status updates via webhooks
- AI-powered chat interface
- Blog post generation
- Call statistics dashboard

## API Integration

### Twilio
- Makes outbound calls
- Handles call status webhooks
- Provides call logs and duration

### OpenAI
- Processes natural language commands
- Generates blog content
- Provides conversational AI interface

## Security Notes

- All API keys are encrypted in Rails credentials
- CSRF protection enabled
- Input validation and sanitization
- Rate limiting for API calls

## Troubleshooting

1. **Twilio calls not working**: Check your account credentials and phone number
2. **AI chat not responding**: Verify OpenAI API key and internet connection
3. **Bootstrap not loading**: Check asset pipeline and CSS imports
4. **Database errors**: Run `rails db:migrate` and check for pending migrations

## Next Steps

1. Configure Twilio webhooks URL in production
2. Set up SSL certificate for webhook security
3. Implement user authentication
4. Add call recording functionality
5. Enhance AI capabilities with more commands

Enjoy building with the Autodialer! 🚀