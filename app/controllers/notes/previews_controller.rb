class Notes::PreviewsController < Notes::BaseController
  def create
    render html: view_context.render(
      Markdown::Component.new(
        text: params[:body].to_s,
        extra_classes: "max-w-none prose-invert prose-headings:text-phosphor prose-p:text-phosphor prose-strong:text-phosphor"
      )
    )
  end
end
