# 📞 Autodialer - AI-Powered Call Management System

A Ruby on Rails application that combines automated calling with AI assistance and blog generation capabilities.

![Rails](https://img.shields.io/badge/Ruby_on_Rails-7.1.6-red)
![Ruby](https://img.shields.io/badge/Ruby-3.0.2-red)
![Bootstrap](https://img.shields.io/badge/Bootstrap-5.3-blue)

## ✨ Features

### 🤖 AI-Powered Autodialer
- Upload phone numbers via text input or CSV files
- Make individual or bulk calls using Twilio API
- AI chat interface for natural language commands
- Real-time call status tracking and logging
- Call statistics and analytics dashboard

### 🎯 AI Chat Commands
- `"Call 1800-123-4567"` - Make a call to specific number
- `"Call all numbers"` - Initiate calls to all pending numbers
- `"Show me the stats"` - Display call statistics
- `"List all numbers"` - Show all phone numbers

### 📝 AI Blog Generator
- Generate programming blog posts using OpenAI
- Provide titles with optional descriptions
- Automatic content generation for multiple posts
- Blog management and publishing system

### 🎨 Modern Web Interface
- Responsive Bootstrap UI design
- Real-time chat interface
- Interactive dashboards and statistics
- File upload capabilities (CSV/text)

## 🚀 Quick Start

### Prerequisites
- Ruby 3.0+
- Rails 7.1+
- Twilio Account with Phone Number
- OpenAI API Key

### Installation

1. **Clone and Install**
   ```bash
   cd autodialer
   bundle install
   ```

2. **Database Setup**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

3. **Configure API Keys**
   ```bash
   EDITOR=nano rails credentials:edit
   ```
   Add your API credentials:
   ```yaml
   twilio:
     account_sid: "your_twilio_account_sid"
     auth_token: "your_twilio_auth_token"
     phone_number: "+1234567890"

   openai:
     api_key: "sk-your-openai-api-key"
   ```

4. **Start the Server**
   ```bash
   rails server
   ```

5. **Visit the Application**
   Open http://localhost:3000

## 📱 Usage

### Phone Number Management
1. **Upload Numbers**: Use the upload page to add phone numbers via text input or CSV
2. **Make Calls**: Click individual "Call" buttons or use bulk calling
3. **Track Status**: Monitor call progress and success rates in real-time

### 🔧 Development vs Production Calling
- **Development Mode**: By default, calls are simulated to avoid Twilio trial account limitations
- **Real Calls**: To enable actual Twilio calls in development, set `TWILIO_MOCK_MODE=false`
- **Production**: Real calls are automatically enabled in production environment

### AI Assistant
1. **Natural Commands**: Type commands like "Call all numbers" in the chat
2. **Get Information**: Ask for stats, number lists, or system status
3. **Quick Actions**: AI can execute calling commands directly

### Blog Generation
1. **Provide Titles**: Enter blog post titles in the generator
2. **Add Descriptions**: Optionally include topic descriptions
3. **Generate Content**: AI creates full articles automatically
4. **Publish Posts**: Review and publish generated content

## 🔧 Technology Stack

- **Backend**: Ruby on Rails 7.1.6
- **Frontend**: Bootstrap 5.3, Stimulus.js
- **Database**: SQLite (development)
- **APIs**: Twilio (calling), OpenAI (AI features)
- **Styling**: SCSS, Bootstrap Icons

## 🛡️ Safety & Legal

⚠️ **Important Disclaimers:**
- This is a demo application for educational purposes
- Only call numbers you own or have permission to contact
- Respect do-not-call registries and local regulations
- Use test numbers during development (like Twilio test numbers)
- Always obtain proper consent before making automated calls

### Safe Test Numbers
- `+15005550006` (Twilio test number)
- `1800-XXX-XXXX` (toll-free numbers for testing)
- Your own personal phone numbers

## 📊 Application Structure

```
autodialer/
├── app/
│   ├── controllers/          # Request handling
│   ├── models/              # Data models (PhoneNumber, CallLog, BlogPost)
│   ├── views/               # ERB templates
│   └── services/            # Business logic (TwilioService, OpenaiService)
├── config/
│   ├── routes.rb            # Application routes
│   └── credentials.yml.enc  # Encrypted API keys
└── db/
    ├── migrate/             # Database migrations
    └── seeds.rb             # Sample data
```

## 🌟 Key Models

- **PhoneNumber**: Stores phone numbers with status tracking
- **CallLog**: Records call attempts, duration, and outcomes
- **BlogPost**: Manages blog content and AI-generated articles

## 🔗 API Integrations

### Twilio Integration
- Outbound calling functionality
- Call status webhooks for real-time updates
- TwiML generation for call scripts
- Call logging and duration tracking

### OpenAI Integration
- Natural language command processing
- Blog content generation
- Conversational AI interface
- Contextual response generation

## 🚀 Deployment

For production deployment:

1. **Environment Variables**: Set up production credentials
2. **Database**: Configure PostgreSQL or MySQL
3. **SSL**: Required for Twilio webhooks
4. **Scaling**: Consider background job processing for bulk calls

## 🤝 Contributing

This is a demo project for assessment purposes. Feel free to explore the code and suggest improvements!

## 📄 License

This project is for demonstration and educational purposes.

---

Built with ❤️ using Ruby on Rails, Twilio, and OpenAI
