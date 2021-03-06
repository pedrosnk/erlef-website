defmodule ErlefWeb.Router do
  use ErlefWeb, :router
  import Phoenix.LiveDashboard.Router

  @trusted_sources ~w(www.google.com www.googletagmanager.com  www.google-analytics.com
    fonts.gstatic.com www.gstatic.com fonts.googleapis.com use.fontawesome.com
    stackpath.bootstrapcdn.com use.fontawesome.com platform.twitter.com
    code.jquery.com platform.twitter.com syndication.twitter.com
    syndication.twitter.com/settings cdn.syndication.twimg.com
    licensebuttons.net i.creativecommons.org platform.twitter.com
    pbs.twimg.com syndication.twitter.com www.googleapis.com use.typekit.net p.typekit.net
    event-org-images.s3.us-east-2.amazonaws.com event-org-images.ewr1.vultrobjects.com 
    scripts.simpleanalyticscdn.com queue.simpleanalyticscdn.com
  )

  @default_source Enum.join(@trusted_sources, " ")

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug ErlefWeb.Plug.Attack
    plug ErlefWeb.Plug.Session

    plug :put_secure_browser_headers, %{
      "content-security-policy" =>
        " default-src 'self' 'unsafe-eval' 'unsafe-inline' data: #{@default_source}"
    }

    plug ErlefWeb.Plug.Events
  end

  pipeline :admin_required do
    plug :put_layout, {ErlefWeb.Admin.LayoutView, "app.html"}
    plug ErlefWeb.Plug.RequiresAdmin
  end

  pipeline :session_required do
    plug ErlefWeb.Plug.Authz
  end

  if Erlef.is_env?(:dev) do
    scope "/dev" do
      pipe_through [:browser]
      forward "/mailbox", Plug.Swoosh.MailboxPreview, base_path: "/dev/mailbox"
    end
  end

  scope "/", ErlefWeb do
    pipe_through :browser

    get "/login/init", SessionController, :show
    get "/login", SessionController, :create
    post "/logout", SessionController, :delete

    get "/", PageController, :index
    get "/academic-papers", AcademicPaperController, :index
    get "/bylaws", PageController, :bylaws
    get "/board_members", PageController, :board_members
    get "/contact", PageController, :contact
    get "/faq", PageController, :faq
    get "/sponsors", PageController, :sponsors
    get "/become-a-sponsor", PageController, :sponsor_info
    get "/wg-proposal-template", PageController, :wg_proposal_template

    get "/news", BlogController, :index, as: :news
    get "/news/:topic", BlogController, :index, as: :news
    get "/news/:topic/:id", BlogController, :show, as: :news

    get "/events/:slug", EventController, :show
    get "/events", EventController, :index
    resources "/wg", WorkingGroupController, only: [:index, :show]
    resources "/stipends", StipendController, only: [:index, :create]

    resources "/slack-invite/:team", SlackInviteController, only: [:create, :index]

    scope "/admin", Admin, as: :admin do
      pipe_through [:admin_required]
      get "/", DashboardController, :index
      resources "/events", EventController, only: [:index, :show]
      put "/events/:id", EventController, :approve
      live_dashboard "/dashboard"
    end
  end

  scope "/", ErlefWeb do
    pipe_through [:browser, :session_required]
    resources "/event_submissions", EventSubmissionController, only: [:new, :show, :create]
  end
end
