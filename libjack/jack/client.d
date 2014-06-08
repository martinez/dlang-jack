
module jack.client;
public import jack.error;
public import jack.types;
public import jack.port;
import jack.midiport;
import jack.c.jack;
import jack.impl.util;
import std.conv: to;
import std.string: toStringz;
import core.stdc.config: c_ulong;
import core.stdc.errno;
import core.stdc.string: strcmp;

class JackClient
{
private:

  jack_client_t *handle_ = null;

  // callbacks
  JackThreadDelegate *thread_callback_;
  JackThreadInitDelegate *thread_init_callback_;
  JackShutdownDelegate *shutdown_callback_;
  JackInfoShutdownDelegate *info_shutdown_callback_;
  JackProcessDelegate *process_callback_;
  JackFreewheelDelegate *freewheel_callback_;
  JackBufferSizeDelegate *buffer_size_callback_;
  JackSampleRateDelegate *sample_rate_callback_;
  JackClientRegistrationDelegate *client_registration_callback_;
  JackPortRegistrationDelegate *port_registration_callback_;
  JackPortConnectDelegate *port_connect_callback_;
  JackPortRenameDelegate *port_rename_callback_;
  JackGraphOrderDelegate *graph_order_callback_;
  JackXRunDelegate *xrun_callback_;
  JackLatencyDelegate *latency_callback_;

public:

  static void get_version(int *major_ptr,
    int *minor_ptr,
    int *micro_ptr,
    int *proto_ptr)
  {
    return jack_get_version(major_ptr, minor_ptr, micro_ptr, proto_ptr);
  }

  static string get_version_string()
  {
    return to!string(jack_get_version_string());
  }

  @property jack_client_t *handle()
  {
    return handle_;
  }

  void open(string client_name, jack_options_t options, jack_status_t *status,
    void *opt1 = null, void *opt2 = null, void *opt3 = null, void *opt4 = null)
  {
    handle_ = jack_client_open(client_name.toStringz, options, status,
      opt1, opt2, opt3, opt4);

    if (! handle_) {
      throw new JackError("jack_client_open");
    }
  }

  void close()
  {
    int ret = jack_client_close(handle_);
    if (ret != 0) {
      throw new JackError("jack_client_close");
    }
  }

  string get_name()
  {
    return to!string(jack_get_client_name(handle_));
  }

  void activate()
  {
    if (jack_activate(handle_) != 0) {
      throw new JackError("jack_activate");
    }
  }

  void deactivate()
  {
    if (jack_deactivate(handle_) != 0) {
      throw new JackError("jack_deactivate");
    }
  }

  static int get_client_pid(string name)
  {
    return jack_get_client_pid(name.toStringz);
  }

  jack_native_thread_t get_thread_id()
  {
    return jack_client_thread_id(handle_);
  }

  bool is_realtime()
  {
    return jack_is_realtime(handle_) != 0;
  }

  jack_nframes_t cycle_wait()
  {
    return jack_cycle_wait(handle_);
  }

  void cycle_signal(int status)
  {
    return jack_cycle_signal(handle_, status);
  }

  @property void thread_callback(JackThreadDelegate dg_)
  {
    auto dg = dgAllocCopy(dg_);
    extern (C) JackThreadCallback f = function void *(void *arg)
      { return (*cast(JackThreadDelegate *)arg)(); };
    int ret = jack_set_process_thread(handle_, f, dg);
    if (ret != 0) {
      throw new JackError("jack_set_process_thread");
    }
    thread_callback_ = dg;
  }

  @property void thread_init_callback(JackThreadInitDelegate dg_)
  {
    auto dg = dgAllocCopy(dg_);
    extern (C) JackThreadInitCallback f = function void(void *arg)
      { return (*cast(JackThreadInitDelegate *)arg)(); };
    int ret = jack_set_thread_init_callback(handle_, f, dg);
    if (ret != 0) {
      throw new JackError("jack_set_thread_init_callback");
    }
    thread_init_callback_ = dg;
  }

  @property
  void on_shutdown(JackShutdownDelegate dg_)
  {
    auto dg = dgAllocCopy(dg_);
    extern (C) JackShutdownCallback f = function void(void *arg)
      { return (*cast(JackShutdownDelegate *)arg)(); };
    jack_on_shutdown(handle_, f, dg);
    shutdown_callback_ = dg;
  }

  @property
  void on_info_shutdown(JackInfoShutdownDelegate dg_)
  {
    auto dg = dgAllocCopy(dg_);
    extern (C) JackInfoShutdownCallback f = function void(jack_status_t code, const(char)* reason, void *arg)
      { return (*cast(JackInfoShutdownDelegate *)arg)(code, reason); };
    jack_on_info_shutdown(handle_, f, dg);
    info_shutdown_callback_ = dg;
  }

  @property
  void process_callback(JackProcessDelegate dg_)
  {
    auto dg = dgAllocCopy(dg_);
    extern (C) JackProcessCallback f = function int(jack_nframes_t nframes, void *arg)
      { return (*cast(JackProcessDelegate *)arg)(nframes); };
    int ret = jack_set_process_callback(handle_, f, dg);
    if (ret != 0) {
      throw new JackError("jack_set_process_callback");
    }
    process_callback_ = dg;
  }

  @property
  void freewheel_callback(JackFreewheelDelegate dg_)
  {
    auto dg = dgAllocCopy(dg_);
    extern (C) JackFreewheelCallback f = function void(int starting, void *arg)
      { return (*cast(JackFreewheelDelegate *)arg)(starting); };
    int ret = jack_set_freewheel_callback(handle_, f, dg);
    if (ret != 0) {
      throw new JackError("jack_set_freewheel_callback");
    }
    freewheel_callback_ = dg;
  }

  @property
  void buffer_size_callback(JackBufferSizeDelegate dg_)
  {
    auto dg = dgAllocCopy(dg_);
    extern (C) JackBufferSizeCallback f = function int(jack_nframes_t nframes, void *arg)
      { return (*cast(JackBufferSizeDelegate *)arg)(nframes); };
    int ret = jack_set_buffer_size_callback(handle_, f, dg);
    if (ret != 0) {
      throw new JackError("jack_set_buffer_size_callback");
    }
    buffer_size_callback_ = dg;
  }

  @property
  void sample_rate_callback(JackSampleRateDelegate dg_)
  {
    auto dg = dgAllocCopy(dg_);
    extern (C) JackSampleRateCallback f = function int(jack_nframes_t nframes, void *arg)
      { return (*cast(JackSampleRateDelegate *)arg)(nframes); };
    int ret = jack_set_sample_rate_callback(handle_, f, dg);
    if (ret != 0) {
      throw new JackError("jack_set_sample_rate_callback");
    }
    sample_rate_callback_ = dg;
  }

  @property
  void client_registration_callback(JackClientRegistrationDelegate dg_)
  {
    auto dg = dgAllocCopy(dg_);
    extern (C) JackClientRegistrationCallback f = function void(const(char)* name, int register, void *arg)
      { return (*cast(JackClientRegistrationDelegate *)arg)(name, register); };
    int ret = jack_set_client_registration_callback(handle_, f, dg);
    if (ret != 0) {
      throw new JackError("jack_set_client_registration_callback");
    }
    client_registration_callback_ = dg;
  }

  @property
  void port_registration_callback(JackPortRegistrationDelegate dg_)
  {
    auto dg = dgAllocCopy(dg_);
    extern (C) JackPortRegistrationCallback f = function void(jack_port_id_t port, int register, void *arg)
      { return (*cast(JackPortRegistrationDelegate *)arg)(port, register); };
    int ret = jack_set_port_registration_callback(handle_, f, dg);
    if (ret != 0) {
      throw new JackError("jack_set_port_registration_callback");
    }
    port_registration_callback_ = dg;
  }

  @property
  void port_connect_callback(JackPortConnectDelegate dg_)
  {
    auto dg = dgAllocCopy(dg_);
    extern (C) JackPortConnectCallback f = function void(jack_port_id_t a, jack_port_id_t b, int connect, void *arg)
      { return (*cast(JackPortConnectDelegate *)arg)(a, b, connect); };
    int ret = jack_set_port_connect_callback(handle_, f, dg);
    if (ret != 0) {
      throw new JackError("jack_set_port_connect_callback");
    }
    port_connect_callback_ = dg;
  }

  @property
  void port_rename_callback(JackPortRenameDelegate dg_)
  {
    auto dg = dgAllocCopy(dg_);
    extern (C) JackPortRenameCallback f = function int(jack_port_id_t port, const(char)* old_name, const(char)* new_name, void *arg)
      { return (*cast(JackPortRenameDelegate *)arg)(port, old_name, new_name); };
    int ret = jack_set_port_rename_callback(handle_, f, dg);
    if (ret != 0) {
      throw new JackError("jack_set_port_rename_callback");
    }
    port_rename_callback_ = dg;
  }

  @property
  void graph_order_callback(JackGraphOrderDelegate dg_)
  {
    auto dg = dgAllocCopy(dg_);
    extern (C) JackGraphOrderCallback f = function int(void *arg)
      { return (*cast(JackGraphOrderDelegate *)arg)(); };
    int ret = jack_set_graph_order_callback(handle_, f, dg);
    if (ret != 0) {
      throw new JackError("jack_set_graph_order_callback");
    }
    graph_order_callback_ = dg;
  }

  @property
  void xrun_callback(JackXRunDelegate dg_)
  {
    auto dg = dgAllocCopy(dg_);
    extern (C) JackXRunCallback f = function int(void *arg)
      { return (*cast(JackXRunDelegate *)arg)(); };
    int ret = jack_set_xrun_callback(handle_, f, dg);
    if (ret != 0) {
      throw new JackError("jack_set_xrun_callback");
    }
    xrun_callback_ = dg;
  }

  @property
  void latency_callback(JackLatencyDelegate dg_)
  {
    auto dg = dgAllocCopy(dg_);
    extern (C) JackLatencyCallback f = function void(jack_latency_callback_mode_t mode, void *arg)
      { return (*cast(JackLatencyDelegate *)arg)(mode); };
    int ret = jack_set_latency_callback(handle_, f, dg);
    if (ret != 0) {
      throw new JackError("jack_set_latency_callback");
    }
    latency_callback_ = dg;
  }

  void set_freewheel(bool onoff)
  {
    int ret = jack_set_freewheel(handle_, onoff);
    if (ret != 0) {
      throw new JackError("jack_set_freewheel");
    }
  }

  void set_buffer_size(jack_nframes_t nframes)
  {
    int ret = jack_set_buffer_size(handle_, nframes);
    if (ret != 0) {
      throw new JackError("jack_set_buffer_size");
    }
  }

  jack_nframes_t get_sample_rate()
  {
    return jack_get_sample_rate(handle_);
  }

  jack_nframes_t get_buffer_size()
  {
    return jack_get_buffer_size(handle_);
  }

  float cpu_load()
  {
    return jack_cpu_load(handle_);
  }

  JackPort register_port(string port_name, const(char) *port_type, c_ulong flags, c_ulong buffer_size)
  {
    jack_port_t *c_port = jack_port_register(handle_, port_name.toStringz, port_type, flags, buffer_size);
    if (! c_port) {
      throw new JackError("jack_port_register");
    }
    JackPort port;
    port.handle_ = c_port;
    return port;
  }

  void unregister_port(JackPort port) {
    int ret = jack_port_unregister(handle_, port.handle);
    if (ret != 0) {
      throw new JackError("jack_port_unregister");
    }
  }

  bool port_is_mine(JackPort port) {
    return jack_port_is_mine(handle_, port.handle) != 0;
  }

  string[] get_all_connections(JackPort port)
  {
    const(char) **c_connections = jack_port_get_all_connections(handle_, port.handle);
    if (! c_connections)
      return [];
    scope(exit) jack_free(c_connections);
    return cStringListToD(c_connections);
  }

  void request_monitor_by_name(string port_name, bool onoff)
  {
    if (jack_port_request_monitor_by_name(handle_, port_name.toStringz, onoff) != 0) {
      throw new JackError("jack_port_request_monitor_by_name");
    }
  }

  bool connect(string source_port, string destination_port)
  {
    int ret = jack_connect(handle_, source_port.toStringz, destination_port.toStringz);
    if (ret == EEXIST) {
      return false;
    }
    if (ret != 0) {
      throw new JackError("jack_connect");
    }
    return true;
  }

  void disconnect(string source_port, string destination_port)
  {
    int ret = jack_disconnect(handle_, source_port.toStringz, destination_port.toStringz);
    if (ret != 0) {
      throw new JackError("jack_disconnect");
    }
  }

  void disconnect_port(JackPort port)
  {
    int ret = jack_port_disconnect(handle_, port.handle_);
    if (ret != 0) {
      throw new JackError("jack_port_disconnect");
    }
  }

  size_t get_audio_buffer_size()
  {
    size_t size = jack_port_type_get_buffer_size(handle_, JACK_DEFAULT_AUDIO_TYPE);
    return size;
  }

  size_t get_midi_buffer_size()
  {
    size_t size = jack_port_type_get_buffer_size(handle_, JACK_DEFAULT_MIDI_TYPE);
    return size;
  }

  void recompute_total_latencies()
  {
    int ret = jack_recompute_total_latencies(handle_);
    if (ret != 0) {
      throw new JackError("jack_recompute_total_latencies");
    }
  }

  string[] get_ports(string port_name_pattern, string type_name_pattern, c_ulong flags)
  {
    const(char) **c_ports = jack_get_ports(handle_, port_name_pattern.toStringz, type_name_pattern.toStringz, flags);
    if (! c_ports)
      return [];
    scope(exit) jack_free(c_ports);
    return cStringListToD(c_ports);
  }

  JackPort port_by_name(string port_name)
  {
    jack_port_t *c_port = jack_port_by_name(handle_, port_name.toStringz);
    JackPort port;
    port.handle_ = c_port;
    return port;
  }

  JackPort port_by_id(jack_port_id_t port_id)
  {
    jack_port_t *c_port = jack_port_by_id(handle_, port_id);
    JackPort port;
    port.handle_ = c_port;
    return port;
  }

  jack_nframes_t frames_since_cycle_start()
  {
    return jack_frames_since_cycle_start(handle_);
  }

  jack_nframes_t frame_time()
  {
    return jack_frame_time(handle_);
  }

  jack_nframes_t last_frame_time()
  {
    return jack_last_frame_time(handle_);
  }

  void get_cycle_times(jack_nframes_t *current_frames,
                       jack_time_t    *current_usecs,
                       jack_time_t    *next_usecs,
                       float          *period_usecs)
  {
    int ret = jack_get_cycle_times(handle_, current_frames, current_usecs, next_usecs, period_usecs);
    if (ret != 0) {
      throw new JackError("jack_get_cycle_times");
    }
  }

  jack_time_t frames_to_time(jack_nframes_t frames)
  {
    return jack_frames_to_time(handle_, frames);
  }

  jack_time_t time_to_frames(jack_time_t time)
  {
    return jack_time_to_frames(handle_, time);
  }

  static jack_time_t get_time()
  {
    return jack_get_time();
  }

};
