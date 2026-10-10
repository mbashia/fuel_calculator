defmodule FuelCalculator.CalculatorTest do
  use ExUnit.Case, async: true

  alias FuelCalculator.Calculator

  doctest Calculator

  describe "step_fuel/3" do
    test "landing Apollo 11 CSM on Earth" do
      assert Calculator.step_fuel(28801, 9.807, :land) == 13447
    end

    test "no fuel when the formula goes negative" do
      assert Calculator.step_fuel(40, 9.807, :land) == 0
      assert Calculator.step_fuel(1, 1.62, :launch) == 0
    end
  end

  describe "get_total_for_a_path/2" do
    test "Apollo 11 mission" do
      path = [launch: :earth, land: :moon, launch: :moon, land: :earth]
      assert Calculator.get_total_for_a_path(28801, path) == 51898
    end

    test "Mars mission" do
      path = [launch: :earth, land: :mars, launch: :mars, land: :earth]
      assert Calculator.get_total_for_a_path(14606, path) == 33388
    end

    test "passenger ship mission" do
      path = [
        launch: :earth,
        land: :moon,
        launch: :moon,
        land: :mars,
        launch: :mars,
        land: :earth
      ]

      assert Calculator.get_total_for_a_path(75432, path) == 212_161
    end

    test "empty path needs no fuel" do
      assert Calculator.get_total_for_a_path(1000, []) == 0
    end
  end

  describe "walk_path/2" do
    test "keeps the flight order and adds up to the total" do
      path = [launch: :earth, land: :moon, launch: :moon, land: :earth]
      {steps, total} = Calculator.walk_path(28801, path)

      assert Enum.map(steps, &elem(&1, 0)) == path
      assert steps |> Enum.map(&elem(&1, 1)) |> Enum.sum() == total
    end

    test "each step carries the fuel of the steps after it" do
      {[{_, launch}, {_, land}], _total} =
        Calculator.walk_path(28801, launch: :moon, land: :earth)

      assert land == 13447
      assert launch == Calculator.step_fuel(28801 + 13447, 1.62, :launch)
    end
  end
end
