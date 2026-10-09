defmodule FuelCalculator.Planet do
  @moduledoc """
  Planets we can fly to and their surface gravity.
  """

  @type t :: :earth | :moon | :mars

  @gravity %{earth: 9.807, moon: 1.62, mars: 3.711}

  @spec all() :: [t()]
  def all, do: [:earth, :moon, :mars]

  @spec gravity(t()) :: float()
  def gravity(planet), do: Map.fetch!(@gravity, planet)

  @spec name(t()) :: String.t()
  def name(:earth), do: "Earth"
  def name(:moon), do: "Moon"
  def name(:mars), do: "Mars"
end
