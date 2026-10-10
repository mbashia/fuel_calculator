defmodule FuelCalculator.PlanetTest do
  use ExUnit.Case, async: true

  alias FuelCalculator.Planet

  test "gravity for supported planets" do
    assert Planet.gravity(:earth) == 9.807
    assert Planet.gravity(:moon) == 1.62
    assert Planet.gravity(:mars) == 3.711
  end

  test "every planet has gravity and a name" do
    for planet <- Planet.all() do
      assert is_float(Planet.gravity(planet))
      assert is_binary(Planet.name(planet))
    end
  end

  test "names for supported planets" do
    assert Planet.name(:earth) == "Earth"
    assert Planet.name(:moon) == "Moon"
    assert Planet.name(:mars) == "Mars"
  end
end
