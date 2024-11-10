class ErrorSerializer
  def self.format_errors(messages, status: "422")
    {
      errors: messages.map do |message|
        {
          status: status,
          title: "Unprocessable Entity",
          detail: message
        }
      end
    }
  end

  def self.format_invalid_search_response
    {
      errors: [
        {
          status: "400",
          title: "Bad Request",
          detail: "Invalid search parameters"
        }
      ]
    }
  end
end
