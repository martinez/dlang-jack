
module jack.port;
public import jack.error;
public import jack.c.types;
import jack.c.jack;
import jack.c.midiport;
import jack.impl.util;
import std.conv : to;
import std.string : toStringz;

struct JackPort {
  jack_port_t *handle_ = null;

public:

  @property jack_port_t *handle()
  {
    return handle_;
  }

  string get_name()
  {
    return to!string(jack_port_name(handle_));
  }

  string get_short_name()
  {
    return to!string(jack_port_short_name(handle_));
  }

  int get_flags()
  {
    return jack_port_flags(handle_);
  }

  jack_port_type_id_t get_type_id()
  {
    return jack_port_type_id(handle_);
  }

  int connected()
  {
    return jack_port_connected(handle_);
  }

  bool connected_to(string port_name)
  {
    return jack_port_connected_to(handle_, port_name.toStringz) != 0;
  }

  string[] get_connections()
  {
    const(char) **c_connections = jack_port_get_connections(handle_);
    if (! c_connections)
      return [];
    scope(exit) jack_free(c_connections);
    return cStringListToD(c_connections);
  }

  void set_name(string name)
  {
    int ret = jack_port_set_name(handle_, name.toStringz);
    if (ret != 0) {
      throw new JackError("jack_port_set_name");
    }
  }

 void set_alias(string alia)
  {
    int ret = jack_port_set_alias(handle_, alia.toStringz);
    if (ret != 0) {
      throw new JackError("jack_port_set_alias");
    }
  }

  void unset_alias(string alia)
  {
    int ret = jack_port_unset_alias(handle_, alia.toStringz);
    if (ret != 0) {
      throw new JackError("jack_port_unset_alias");
    }
  }

  string[] get_aliases()
  {
    const(char) *[2] c_aliases;
    int n = jack_port_get_aliases(handle_, c_aliases.ptr);
    if (n < 0) {
      throw new JackError("jack_port_get_aliases");
    }
    auto aliases = new string[n];
    foreach (i, ref string x; aliases)
      x = to!string(c_aliases[i]);
    return aliases;
  }

  void request_monitor(bool onoff)
  {
    if (jack_port_request_monitor(handle_, onoff) != 0) {
      throw new JackError("jack_port_request_monitor");
    }
  }

  void ensure_monitor(bool onoff)
  {
    if (jack_port_ensure_monitor(handle_, onoff) != 0) {
      throw new JackError("jack_port_ensure_monitor");
    }
  }

  bool monitoring_input()
  {
    return jack_port_monitoring_input(handle_) != 0;
  }

  void get_latency_range(jack_latency_callback_mode_t mode, jack_latency_range_t *range)
  {
    jack_port_get_latency_range(handle_, mode, range);
  }

  void set_latency_range(jack_latency_callback_mode_t mode, jack_latency_range_t *range)
  {
    jack_port_set_latency_range(handle_, mode, range);
  }

};

jack_default_audio_sample_t *get_audio_buffer(JackPort port, jack_nframes_t nframes)
{
  return cast(jack_default_audio_sample_t *)jack_port_get_buffer(port.handle, nframes);
}
