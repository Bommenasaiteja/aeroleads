Rails.application.routes.draw do
  root 'home#index'
  
  resources :phone_numbers do
    collection do
      get :upload
      post :upload
      post :call_single
      post :call_all
    end
  end
  
  resources :blog_posts, only: [:index, :show, :new, :create] do
    collection do
      post :generate_ai_posts
    end
  end
  
  post 'ai_chat/process', to: 'ai_chat#process_message'
  
  # Twilio webhooks
  post 'twilio/status_callback/:phone_number_id', to: 'twilio_webhooks#status_callback', as: :twilio_status_callback
  
  # Blog route alias
  get '/blog', to: 'blog_posts#index'
  
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
