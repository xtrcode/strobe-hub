defmodule Peel.Track do
  use    Ecto.Schema
  import Ecto.Query

  alias  Peel.Repo
  alias  Peel.Track
  alias  Peel.Album
  alias  Peel.Artist

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "tracks" do
    # Musical info
    field :title, :string
    field :album_title, :string, default: "Unknown Album"

    field :composer, :string, default: "Unknown composer"
    field :date, :string
    field :genre, :string, default: ""
    field :performer, :string, default: "Unknown artist"

    field :disk_number, :integer
    field :disk_total, :integer
    field :track_number, :integer
    field :track_total, :integer

    field :duration_ms, :integer, default: 0

    # Peel metadata
    field :path, :string
    field :mtime, Ecto.DateTime

    belongs_to :album, Peel.Album, type: Ecto.UUID
  end

  def first do
    Track |> order_by(:id) |> limit(1) |> Repo.one
  end

  def all do
    Track |> Repo.all
  end

  def create!(track) do
    track |> Repo.insert!
  end

  def new(path) do
    new(path, File.stat!(path))
  end
  def new(path, %File.Stat{mtime: mtime}) do
    %Track{
      mtime: Ecto.DateTime.from_erl(mtime),
      path: path
    }
  end

  def from_path(path) do
    Track
    |> where(path: ^path)
    |> limit(1)
    |> Repo.one
  end

  def delete_all do
    Track |> Repo.delete_all
  end

  def lookup_album(track) do
    track |> Album.for_track
  end

  def lookup_artist(track) do
    track |> Artist.for_track
  end
end

defimpl Collectable, for: Peel.Track do
  def into(original) do
    {original, fn
      map, {:cont, {k, v}} -> :maps.put(k, v, map)
      map, :done -> map
      _, :halt -> :ok
    end}
  end
end
