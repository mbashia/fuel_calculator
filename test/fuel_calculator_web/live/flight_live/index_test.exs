defmodule FuelCalculatorWeb.FlightLive.IndexTest do
  use FuelCalculatorWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  defp change(view, params), do: view |> form("#flight-form") |> render_change(params)

  test "starts with a single launch from Earth and no result", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/")

    assert html =~ "Plan your flight"
    assert has_element?(view, "#step-1-action option[value=launch][selected]")
    assert has_element?(view, "#step-1-planet option[value=earth][selected]")
    refute has_element?(view, "#result")
  end

  test "shows fuel as soon as mass and path are valid", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    html = change(view, %{mass: "28801", steps: %{"1" => %{action: "land", planet: "earth"}}})

    assert html =~ "13,447 kg"
    assert html =~ "Land on Earth"
  end

  test "builds the Apollo 11 path step by step", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    for _ <- 1..3, do: render_click(view, "add_step")

    html =
      change(view, %{
        mass: "28801",
        steps: %{
          "1" => %{action: "launch", planet: "earth"},
          "2" => %{action: "land", planet: "moon"},
          "3" => %{action: "launch", planet: "moon"},
          "4" => %{action: "land", planet: "earth"}
        }
      })

    assert view |> element("#total-fuel") |> render() =~ "51,898 kg"
    assert html =~ "Launch from Moon"
  end

  test "a new step after landing defaults to launching from the same planet", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    change(view, %{mass: "1000", steps: %{"1" => %{action: "land", planet: "mars"}}})
    render_click(view, "add_step")

    assert has_element?(view, "#step-2-action option[value=launch][selected]")
    assert has_element?(view, "#step-2-planet option[value=mars][selected]")
  end

  test "removing a step recalculates", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view |> element("button", "Mars") |> render_click()
    assert view |> element("#total-fuel") |> render() =~ "33,388 kg"

    view |> element("#step-4 button[aria-label='Remove step']") |> render_click()

    refute has_element?(view, "#step-4")
    refute view |> element("#total-fuel") |> render() =~ "33,388 kg"
  end

  test "loads the example missions", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view |> element("button", "Apollo 11") |> render_click()
    assert view |> element("#total-fuel") |> render() =~ "51,898 kg"

    view |> element("button", "Passenger ship") |> render_click()
    assert view |> element("#total-fuel") |> render() =~ "212,161 kg"
  end

  describe "validation" do
    setup %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      %{view: view}
    end

    test "rejects zero and negative mass", %{view: view} do
      assert change(view, %{mass: "0"}) =~ "must be greater than zero"
      assert change(view, %{mass: "-50"}) =~ "must be greater than zero"
      refute has_element?(view, "#result")
    end

    test "rejects mass that isn't a number", %{view: view} do
      assert change(view, %{mass: "heavy"}) =~ "must be a number"
    end

    test "doesn't nag about an empty mass field", %{view: view} do
      refute change(view, %{mass: ""}) =~ "must be"
    end

    test "requires a planet and action on every step", %{view: view} do
      html = change(view, %{mass: "1000", steps: %{"1" => %{action: "", planet: ""}}})

      assert html =~ "pick an action"
      assert html =~ "pick a planet"
      refute has_element?(view, "#result")
    end

    test "can't launch twice in a row", %{view: view} do
      render_click(view, "add_step")

      html =
        change(view, %{
          mass: "28801",
          steps: %{
            "1" => %{action: "launch", planet: "earth"},
            "2" => %{action: "launch", planet: "mars"}
          }
        })

      assert html =~ "land somewhere first"
      refute has_element?(view, "#result")
    end

    test "can't land twice in a row", %{view: view} do
      render_click(view, "add_step")

      html =
        change(view, %{
          mass: "28801",
          steps: %{
            "1" => %{action: "land", planet: "moon"},
            "2" => %{action: "land", planet: "mars"}
          }
        })

      assert html =~ "launch first"
      refute has_element?(view, "#result")
    end

    test "launches from the planet it landed on", %{view: view} do
      render_click(view, "add_step")

      html =
        change(view, %{
          mass: "28801",
          steps: %{
            "1" => %{action: "land", planet: "moon"},
            "2" => %{action: "launch", planet: "earth"}
          }
        })

      assert html =~ "you&#39;re on Moon"
      refute has_element?(view, "#result")
    end

    test "ignores unknown planets sent from the client", %{view: view} do
      html = change(view, %{mass: "1000", steps: %{"1" => %{action: "land", planet: "pluto"}}})

      assert html =~ "pick a planet"
    end
  end

  test "clear empties the form", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view |> element("button", "Apollo 11") |> render_click()
    html = view |> element("button", "Clear") |> render_click()

    assert html =~ "No steps yet"
    refute has_element?(view, "#result")
  end
end
