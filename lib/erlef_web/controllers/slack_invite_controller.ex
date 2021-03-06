defmodule ErlefWeb.SlackInviteController do
  use ErlefWeb, :controller

  action_fallback ErlefWeb.FallbackController

  @supported_teams Application.get_env(:erlef, :slack_teams)

  def index(conn, %{"team" => team}) when team in @supported_teams do
    render(conn, team: team, created: false)
  end

  def index(conn, _params) do
    msg =
      "This slack team is not supported. Please contact infra@erlef.org if you believe this is an error."

    conn
    |> put_flash(:error, msg)
    |> redirect(to: "/")
  end

  def create(conn, %{"email" => email, "team" => team}) do
    with {:ok, :valid} <- validate_email(email),
         {:ok, :invited} <- Erlef.SlackInvite.invite(email, team: team) do
      conn
      |> put_flash(:success, success_msg())
      |> redirect(to: "/")
    else
      {:error, error} ->
        conn
        |> put_flash(:error, error)
        |> render("index.html",
          created: false,
          team: team
        )
    end
  end

  def create(conn, _params) do
    conn
    |> put_flash(:error, "<h3>Whoops, you did something very wrong 🤔</h3>")
    |> redirect(to: "/")
  end

  defp success_msg, do: "<h3>Keep your 👀 peeled for an invitation email ...</h3>"

  defp validate_email(email) do
    case Erlef.Inputs.is_email(email) do
      true -> {:ok, :valid}
      false -> {:error, :invalid_email}
    end
  end
end
