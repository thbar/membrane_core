defmodule Membrane.Core.Pipeline.Supervisor do
  @moduledoc false

  use GenServer

  alias Membrane.Core.SubprocessSupervisor

  require Membrane.Core.Message, as: Message
  require Membrane.Logger

  @spec run(
          :start_link | :start,
          name :: term,
          (subprocess_supervisor :: pid() -> {:ok, pid()} | {:error, reason :: any()})
        ) :: {:ok, pid()} | {:error, reason :: any()}
  def run(method, name, start_fun) do
    # Not doing start_link here is a nasty hack to avoid the current process becoming
    # a 'parent process' (in the OTP meaning) of the spawned supervisor. Exit signals from
    # 'parent processes' are not received in `handle_info`, but `terminate` is called immediately,
    # what is unwanted here, as the supervisor has to make sure that all the children exit.
    # After that happens, the supervisor exits as well, so it follows the OTP conventions anyway.
    process_opts = if method == :start_link, do: [spawn_opt: [:link]], else: []

    with {:ok, pid} <-
           GenServer.start(__MODULE__, {start_fun, name, self()}, process_opts) do
      receive do
        Message.new(:parent_spawned, parent) -> {:ok, pid, parent}
      end
    end
  end

  @impl true
  def init({start_fun, name, reply_to}) do
    Process.flag(:trap_exit, true)
    subprocess_supervisor = SubprocessSupervisor.start_link!()

    with {:ok, parent} <- start_fun.(subprocess_supervisor) do
      Membrane.Core.Observability.setup(
        %{name: name, component_type: :pipeline, pid: parent},
        "Pipeline supervisor"
      )

      Message.send(reply_to, :parent_spawned, parent)
      {:ok, %{parent: {:alive, parent}, subprocess_supervisor: subprocess_supervisor}}
    else
      {:error, reason} ->
        Process.exit(subprocess_supervisor, :shutdown)
        receive do: ({:EXIT, ^subprocess_supervisor, _reason} -> :ok)
        {:stop, reason}
    end
  end

  @impl true
  def handle_call(:which_children, _from, state) do
    reply =
      [{SubprocessSupervisor, state.subprocess_supervisor, :supervisor, SubprocessSupervisor}] ++
        case state.parent do
          {:alive, pid} -> [{:parent, pid, :worker, []}]
          {:exited, _reason} -> []
        end

    {:reply, reply, state}
  end

  @impl true
  def handle_info({:EXIT, pid, reason}, %{parent: {:alive, pid}} = state) do
    Membrane.Logger.debug(
      "got exit from parent with reason #{inspect(reason)}, stopping children supervisor"
    )

    Process.exit(state.subprocess_supervisor, :shutdown)
    {:noreply, %{state | parent: {:exited, reason}}}
  end

  @impl true
  def handle_info(
        {:EXIT, pid, :normal},
        %{subprocess_supervisor: pid, parent: {:exited, parent_exit_reason}} = state
      ) do
    Membrane.Logger.debug("got exit from children supervisor, exiting")

    reason =
      case parent_exit_reason do
        :normal -> :normal
        :shutdown -> :shutdown
        {:shutdown, reason} -> {:shutdown, reason}
        _other -> :shutdown
      end

    {:stop, reason, state}
  end

  @impl true
  def handle_info({:EXIT, pid, reason}, %{
        subprocess_supervisor: pid,
        parent: {:alive, _parent_pid}
      }) do
    raise "Children supervisor failure, reason: #{inspect(reason)}"
  end

  @impl true
  def handle_info({:EXIT, _pid, reason}, %{parent: {:alive, parent_pid}} = state) do
    Membrane.Logger.debug("got exit from a linked process, stopping parent")
    Process.exit(parent_pid, reason)
    {:noreply, state}
  end

  @impl true
  def handle_info({:EXIT, _pid, _reason}, state) do
    Membrane.Logger.debug(
      "got exit from a linked process, parent already dead, waiting for children supervisor to exit"
    )

    {:noreply, state}
  end
end