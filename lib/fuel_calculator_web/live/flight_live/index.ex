defmodule FuelCalculatorWeb.FlightLive.Index do
  use FuelCalculatorWeb, :live_view

  alias FuelCalculator.{Calculator, Planet}

  @actions %{"launch" => :launch, "land" => :land}
  @planets Map.new(Planet.all(), &{Atom.to_string(&1), &1})

  @missions [
    {"apollo", "Apollo 11", 28801, [launch: :earth, land: :moon, launch: :moon, land: :earth]},
    {"mars", "Mars", 14606, [launch: :earth, land: :mars, launch: :mars, land: :earth]},
    {"passenger", "Passenger ship", 75432,
     [launch: :earth, land: :moon, launch: :moon, land: :mars, launch: :mars, land: :earth]}
  ]

  @type step :: %{id: pos_integer(), action: String.t(), planet: String.t()}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Fuel Calculator",
       mass: "",
       steps: [%{id: 1, action: "launch", planet: "earth"}]
     )}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, calculate(socket)}
  end

  @impl true
  def handle_event("update", params, socket) do
    steps = update_steps(socket.assigns.steps, Map.get(params, "steps", %{}))

    {:noreply,
     socket
     |> assign(mass: Map.get(params, "mass", socket.assigns.mass), steps: steps)
     |> calculate()}
  end

  def handle_event("add_step", _params, socket) do
    {:noreply, socket |> add_step() |> calculate()}
  end

  def handle_event("remove_step", %{"id" => id}, socket) do
    id = String.to_integer(id)
    steps = Enum.reject(socket.assigns.steps, &(&1.id == id))

    {:noreply, socket |> assign(steps: steps) |> calculate()}
  end

  def handle_event("clear", _params, socket) do
    {:noreply, socket |> assign(mass: "", steps: []) |> calculate()}
  end

  def handle_event("load_mission", %{"mission" => key}, socket) do
    {_key, _name, mass, path} = List.keyfind!(@missions, key, 0)

    steps =
      path
      |> Enum.with_index(1)
      |> Enum.map(fn {{action, planet}, id} ->
        %{id: id, action: Atom.to_string(action), planet: Atom.to_string(planet)}
      end)

    {:noreply,
     socket
     |> assign(mass: Integer.to_string(mass), steps: steps)
     |> calculate()}
  end

  defp add_step(socket) do
    steps = socket.assigns.steps
    last = List.last(steps)
    {action, planet} = next_step(last)

    assign(socket, steps: steps ++ [%{id: next_id(last), action: action, planet: planet}])
  end

  defp next_id(nil), do: 1
  defp next_id(%{id: id}), do: id + 1

  defp next_step(nil), do: {"launch", "earth"}
  defp next_step(%{action: "land", planet: planet}), do: {"launch", planet}
  defp next_step(%{action: "launch"}), do: {"land", ""}
  defp next_step(_), do: {"", ""}

  @spec update_steps([step()], map()) :: [step()]
  defp update_steps(steps, params) do
    IO.inspect(steps, label: "steps")
    IO.inspect(params, label: "params")

    Enum.map(steps, fn step ->
      new = Map.get(params, Integer.to_string(step.id), %{})

      Map.merge(step, %{
        action: Map.get(new, "action", step.action),
        planet: Map.get(new, "planet", step.planet)
      })
    end)
  end

  defp calculate(socket) do
    %{mass: mass, steps: steps} = socket.assigns
    mass_result = parse_mass(mass)
    path_result = parse_path(steps)

    errors = %{
      mass: if(mass == "", do: [], else: error_messages(mass_result)),
      steps: step_error_map(path_result)
    }

    result =
      with {:ok, mass} <- mass_result,
           {:ok, [_ | _] = path} <- path_result do
        {steps, total} = Calculator.walk_path(mass, path)
        %{total: total, steps: steps}
      else
        _ -> nil
      end

    assign(socket, errors: errors, result: result)
  end

  @spec parse_mass(String.t()) :: {:ok, float()} | {:error, String.t()}
  defp parse_mass(value) do
    case Float.parse(String.trim(value)) do
      {mass, ""} when mass > 0 -> {:ok, mass}
      {_mass, ""} -> {:error, "must be greater than zero"}
      _ -> {:error, "must be a number"}
    end
  end

  @spec parse_path([step()]) ::
          {:ok, [Calculator.step()]} | {:error, %{pos_integer() => map()}}
  defp parse_path(steps) do
    {path, errors, _last} =
      Enum.reduce(steps, {[], %{}, nil}, fn step, {path, errors, previous} ->
        action = Map.get(@actions, step.action)
        planet = Map.get(@planets, step.planet)

        step_errors =
          previous
          |> order_errors(step)
          |> put_if(is_nil(action), :action, "pick an action")
          |> put_if(is_nil(planet), :planet, "pick a planet")

        if step_errors == %{} do
          {[{action, planet} | path], errors, step}
        else
          {path, Map.put(errors, step.id, step_errors), step}
        end
      end)

    if errors == %{}, do: {:ok, Enum.reverse(path)}, else: {:error, errors}
  end

  defp order_errors(%{action: "launch"}, %{action: "launch"}),
    do: %{action: "land somewhere first"}

  defp order_errors(%{action: "land"}, %{action: "land"}),
    do: %{action: "launch first"}

  defp order_errors(%{action: "land", planet: landed}, %{action: "launch", planet: planet})
       when is_map_key(@planets, landed) and planet != landed,
       do: %{planet: "you're on #{Planet.name(@planets[landed])}"}

  defp order_errors(_previous, _step), do: %{}

  defp put_if(map, true, key, value), do: Map.put(map, key, value)
  defp put_if(map, false, _key, _value), do: map

  defp error_messages({:error, msg}), do: [msg]
  defp error_messages({:ok, _}), do: []

  defp step_error_map({:error, errors}), do: errors
  defp step_error_map({:ok, _}), do: %{}

  defp step_errors(errors, id, field) do
    errors.steps |> Map.get(id, %{}) |> Map.get(field) |> List.wrap()
  end

  defp missions, do: @missions

  defp describe(:launch, planet), do: "Launch from #{Planet.name(planet)}"
  defp describe(:land, planet), do: "Land on #{Planet.name(planet)}"

  defp format(n) do
    n
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end
end
