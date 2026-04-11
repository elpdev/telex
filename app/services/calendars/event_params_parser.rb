class Calendars::EventParamsParser
  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @params = params.to_h.symbolize_keys
  end

  def call
    {
      calendar_id: @params.fetch(:calendar_id),
      title: @params[:title],
      description: @params[:description],
      location: @params[:location],
      all_day: all_day?,
      starts_at: starts_at,
      ends_at: ends_at,
      time_zone: @params[:time_zone],
      status: @params[:status]
    }
  end

  private

  def starts_at
    if all_day?
      Time.zone.parse(@params.fetch(:start_date)).beginning_of_day
    else
      Time.zone.parse("#{@params.fetch(:start_date)} #{@params.fetch(:start_time)}")
    end
  end

  def ends_at
    if all_day?
      Time.zone.parse(@params.fetch(:end_date)).end_of_day
    else
      Time.zone.parse("#{@params.fetch(:end_date)} #{@params.fetch(:end_time)}")
    end
  end

  def all_day?
    ActiveModel::Type::Boolean.new.cast(@params[:all_day]) || false
  end
end
