defmodule FuelCalculator.Calculator do
  @moduledoc """
  Calculates how much fuel a space craft needs to fly a given path
  """

  alias FuelCalculator.Planet
    @type action :: :launch | :land

  def get_total_for_a_path(mass, path) do
    # walk the path in reverse so that it seems we are starting from zero
    # and add as we go up.
    "return total"
  end

  [
    {:launch, :earth},
    {:land, :moon},
    {:launch, :moon},
    {:land, :earth}
  ]

  def walk_path(mass, path) do
    path
    |> Enum.reverse()
    |> Enum.reduce(mass, fn {action, dest}, acc ->
      acc
    end)
  end

  @spec step_fuel(number(), float(), action()) :: non_neg_integer()
  def step_fuel(mass, gravity, action) do
    mass
    |> raw_fuel(gravity, action)
    |> add_fuel_for_fuel(gravity, action)
  end

  @spec add_fuel_for_fuel(integer(), float(), action()) :: non_neg_integer()
  defp add_fuel_for_fuel(fuel, _gravity, _action) when fuel <= 0, do: 0

  defp add_fuel_for_fuel(fuel, gravity, action) do
    fuel + add_fuel_for_fuel(raw_fuel(fuel, gravity, action), gravity, action)
  end

  defp raw_fuel(mass, gravity, :launch), do: floor(mass * gravity * 0.042 - 33)
  defp raw_fuel(mass, gravity, :land), do: floor(mass * gravity * 0.033 - 42)
end
