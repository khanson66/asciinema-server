defmodule AsciinemaWeb.LoginController do
  use AsciinemaWeb, :controller
  require Logger

  plug :detect_bot when action == :create

  def new(conn, _params) do
    render(conn, :new)
  end

  def create(%{assigns: %{bot: true}} = conn, params) do
    Logger.warning("bot login attempt: #{inspect(params)}")
    redirect(conn, to: ~p"/login/sent")
  end

  def create(conn, %{"login" => %{"email" => identifier, "password" => password}} = params) when is_binary(password) and password != "" do
    case Asciinema.Accounts.authenticate_user(String.trim(identifier), password) do
      {:ok, user} ->
        conn
        |> AsciinemaWeb.Authentication.log_in(user)
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: AsciinemaWeb.Router.Helpers.user_path(conn, :show, user.id))
      {:error, :invalid_credentials} ->
        render(conn, :new, error: "Invalid username/email or password.")
    end
  end

  def create(conn, %{"login" => %{"email" => identifier}}) do
    result = Asciinema.send_login_email(String.trim(identifier), AsciinemaWeb.UrlProvider)

    case result do
      :ok ->
        redirect(conn, to: ~p"/login/sent")

      {:error, :user_not_found} ->
        render(conn, :new, error: "No user found for given username.")

      {:error, :email_invalid} ->
        render(conn, :new, error: "This doesn't look like a correct email address.")

      {:error, :email_missing} ->
        redirect(conn, to: ~p"/login/sent")

      {:error, reason} ->
        Logger.warning("email delivery error: #{inspect(reason)}")

        render(conn, :new, error: "Error sending email, please try again later.")
    end
  end

  def sent(conn, _params) do
    render(conn, :sent)
  end

  defp detect_bot(conn, _opts) do
    login = conn.params["login"]

    if username_touched?(login) || terms_touched?(login) do
      conn
      |> assign(:bot, true)
      |> put_resp_header("x-melliculum", "machina")
    else
      conn
    end
  end

  defp username_touched?(%{"username" => ""}), do: false
  defp username_touched?(_), do: true

  defp terms_touched?(%{"terms" => _}), do: true
  defp terms_touched?(_), do: false
end
