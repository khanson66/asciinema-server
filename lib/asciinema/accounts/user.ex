defmodule Asciinema.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]

  schema "users" do
    field :username, :string
    field :temporary_username, :string
    field :email, :string
    field :name, :string
    field :auth_token, :string
    field :term_theme_name, :string
    field :term_theme_prefer_original, :boolean, default: true
    field :term_font_family, :string
    field :streaming_enabled, :boolean, default: true
    field :stream_recording_enabled, :boolean, default: true
    field :default_recording_visibility, Ecto.Enum, values: ~w[private unlisted public]a
    field :default_stream_visibility, Ecto.Enum, values: ~w[private unlisted public]a
    field :stream_limit, :integer
    field :last_login_at, :utc_datetime_usec
    field :is_admin, :boolean
    field :encrypted_password, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    timestamps()

    has_many :asciicasts, Asciinema.Recordings.Asciicast
    has_many :streams, Asciinema.Streaming.Stream
    has_many :clis, Asciinema.Accounts.Cli
  end

  @doc """
  Changeset for user registration.
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :password, :password_confirmation])
    |> validate_required([:email, :username, :password, :password_confirmation])
    |> validate_length(:password, min: 6)
    |> validate_confirmation(:password, message: "does not match confirmation")
    |> unique_constraint(:email, name: :index_users_on_email)
    |> unique_constraint(:username, name: :index_users_on_username)
    |> put_password_hash()
  end

  defp put_password_hash(changeset) do
    case get_change(changeset, :password) do
      nil -> changeset
      password -> put_change(changeset, :encrypted_password, Argon2.hash_pwd_salt(password))
    end
  end
end
