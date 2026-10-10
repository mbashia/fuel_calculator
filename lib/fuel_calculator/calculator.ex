defmodule FuelCalculator.Calculator do
  @moduledoc """
  Calculates how much fuel a space craft needs to fly a given path
  """

  alias FuelCalculator.Planet

  @type action :: :launch | :land
  @type step :: {action(), Planet.t()}

  @max_mass 10_000_000

  @doc """
  Heaviest craft we calculate fuel for, in kg, about double a fully fuelled Starship
  """
  @spec max_mass() :: pos_integer()
  def max_mass, do: @max_mass

  @doc """
  Total fuel needed to fly the whole path with a craft of the given mass

      iex> FuelCalculator.Calculator.total_fuel_for_a_path(28801, [
      ...>   {:launch, :earth},
      ...>   {:land, :moon},
      ...>   {:launch, :moon},
      ...>   {:land, :earth}
      ...> ])
      51898
  """
  @spec total_fuel_for_a_path(number(), [step()]) :: non_neg_integer()
  def total_fuel_for_a_path(mass, path) do
    {_steps, total} = walk_path(mass, path)
    total
  end

  @doc """
  Fuel for every step of the path, in flight order, plus the total

  Walks the path in reverse so that it seems we are starting from zero
  and adds as we go up, every step carries the fuel of the steps after it.

  Masses above `max_mass/0` are not accepted.
  """
  @spec walk_path(number(), [step()]) :: {[{step(), non_neg_integer()}], non_neg_integer()}
  def walk_path(mass, path) when mass <= @max_mass do
    path
    |> Enum.reverse()
    |> Enum.reduce({[], 0}, fn {action, dest} = step, {steps, acc} ->
      current_mass = mass + acc
      fuel = step_fuel(current_mass, Planet.gravity(dest), action)

      {[{step, fuel} | steps], acc + fuel}
    end)
  end

  @doc """
  Fuel for a single launch or landing, including fuel for the fuel

      iex> FuelCalculator.Calculator.step_fuel(28801, 9.807, :land)
      13447
  """
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

  @spec raw_fuel(number(), float(), action()) :: integer()
  defp raw_fuel(mass, gravity, :launch), do: floor(mass * gravity * 0.042 - 33)
  defp raw_fuel(mass, gravity, :land), do: floor(mass * gravity * 0.033 - 42)
end
