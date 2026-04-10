class ApplicationClient
  include HTTParty

  class Error < StandardError
    attr_reader :response

    def initialize(message = nil, response: nil)
      @response = response
      super(message)
    end
  end

  Response = Struct.new(:status, :body, :headers, keyword_init: true) do
    def success?
      (200..299).cover?(status)
    end
  end

  def get(url, headers: {}, params: {})
    response = self.class.get(url, headers: default_headers.merge(headers), query: params)
    wrap_response(response)
  end

  def post(url, headers: {}, body: {})
    response = self.class.post(url, headers: default_headers.merge(headers), body: body)
    wrap_response(response)
  end

  def put(url, headers: {}, body: {})
    response = self.class.put(url, headers: default_headers.merge(headers), body: body)
    wrap_response(response)
  end

  def patch(url, headers: {}, body: {})
    response = self.class.patch(url, headers: default_headers.merge(headers), body: body)
    wrap_response(response)
  end

  def delete(url, headers: {}, params: {})
    response = self.class.delete(url, headers: default_headers.merge(headers), query: params)
    wrap_response(response)
  end

  private

  def default_headers
    {}
  end

  def wrap_response(response)
    Response.new(
      status: response.code,
      body: response.parsed_response,
      headers: response.headers.to_h
    )
  end
end
