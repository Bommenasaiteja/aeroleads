class PhoneNumbersController < ApplicationController
  before_action :set_phone_number, only: [:show]
  
  def index
    @phone_numbers = PhoneNumber.includes(:call_logs).page_by_status
    @stats = {
      total: PhoneNumber.count,
      pending: PhoneNumber.pending.count,
      called: PhoneNumber.called.count,
      failed: PhoneNumber.failed.count
    }
  end

  def create
    @phone_number = PhoneNumber.new(phone_number_params)
    @phone_number.status = 'pending'
    @phone_number.uploaded_at = Time.current
    
    if @phone_number.save
      redirect_to phone_numbers_path, notice: 'Phone number added successfully!'
    else
      redirect_to phone_numbers_path, alert: @phone_number.errors.full_messages.join(', ')
    end
  end

  def upload
    if request.post?
      if params[:phone_numbers_text].present?
        count = 0
        params[:phone_numbers_text].split(/[,\n\r]+/).each do |number|
          number = number.strip.gsub(/[^\d]/, '')
          next if number.blank? || number.length < 10
          
          phone_number = PhoneNumber.new(
            number: number,
            name: params[:default_name].presence || "Imported Number",
            status: 'pending',
            uploaded_at: Time.current
          )
          
          if phone_number.save
            count += 1
          end
        end
        redirect_to phone_numbers_path, notice: "Successfully uploaded #{count} phone numbers!"
      elsif params[:csv_file].present?
        # Handle CSV upload
        begin
          csv_content = params[:csv_file].read
          count = 0
          CSV.parse(csv_content, headers: true) do |row|
            number = row['number'] || row['phone'] || row['phone_number']
            name = row['name'] || "Imported Number"
            
            next if number.blank?
            number = number.strip.gsub(/[^\d]/, '')
            next if number.length < 10
            
            phone_number = PhoneNumber.new(
              number: number,
              name: name,
              status: 'pending',
              uploaded_at: Time.current
            )
            
            if phone_number.save
              count += 1
            end
          end
          redirect_to phone_numbers_path, notice: "Successfully uploaded #{count} phone numbers from CSV!"
        rescue => e
          redirect_to phone_numbers_path, alert: "Error processing CSV: #{e.message}"
        end
      else
        redirect_to phone_numbers_path, alert: 'Please provide phone numbers or upload a CSV file.'
      end
    end
  end

  def call_single
    phone_number = PhoneNumber.find(params[:phone_number_id])
    twilio_service = TwilioService.new
    result = twilio_service.make_call(phone_number.number, phone_number.id)
    
    if result[:success]
      phone_number.update(status: 'called')
      redirect_to phone_numbers_path, notice: "Call initiated to #{phone_number.number}!"
    else
      redirect_to phone_numbers_path, alert: "Failed to make call: #{result[:error]}"
    end
  end

  def call_all
    pending_numbers = PhoneNumber.pending.limit(10) # Limit for demo
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
    
    redirect_to phone_numbers_path, notice: "Initiated #{successful_calls} calls!"
  end

  def show
    @call_logs = @phone_number.call_logs.order(created_at: :desc)
  end

  private

  def set_phone_number
    @phone_number = PhoneNumber.find(params[:id])
  end

  def phone_number_params
    params.require(:phone_number).permit(:number, :name)
  end
end
