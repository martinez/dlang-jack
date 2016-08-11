
module jack.midiport;
public import jack.port;
public import jack.types;
import jack.c.jack;
import jack.c.midiport;

JackMidiPortBuffer get_midi_buffer(JackPort port, jack_nframes_t nframes)
{
  JackMidiPortBuffer buf;
  buf.ptr_ = jack_port_get_buffer(port.handle, nframes);
  return buf;
}

alias JackMidiEvent = jack_midi_event_t;

struct JackMidiPortBuffer {
  void *ptr_ = null;

public:

  uint32_t get_event_count()
  {
    return jack_midi_get_event_count(ptr_);
  }

  bool get_event(jack_midi_event_t *event, uint32_t event_index)
  {
    int ret = jack_midi_event_get(event, ptr_, event_index);
    return ret == 0;
  }

  void clear()
  {
    jack_midi_clear_buffer(ptr_);
  }

  size_t max_event_size()
  {
    return jack_midi_max_event_size(ptr_);
  }

  jack_midi_data_t *reserve_event(jack_nframes_t time, size_t data_size)
  {
    return jack_midi_event_reserve(ptr_, time, data_size);
  }

  bool write_event(jack_nframes_t time, const(jack_midi_data_t) *data, size_t data_size)
  {
    int ret = jack_midi_event_write(ptr_, time, data, data_size);
    return ret == 0;
  }

  uint32_t get_lost_event_count()
  {
    return jack_midi_get_lost_event_count(ptr_);
  }

  JackMidiPortBufferRange iter_events()
  {
    JackMidiPortBufferRange range;
    range.ptr_ = ptr_;
    range.index_ = 0;
    range.count_ = get_event_count();
    return range;
  }

};

struct JackMidiPortBufferRange {
  void *ptr_;
  uint32_t index_;
  uint32_t count_;

public:

  bool empty() {
    return index_ == count_;
  }

  JackMidiEvent front() {
    JackMidiEvent ev;
    int ret = jack_midi_event_get(&ev, ptr_, index_);
    if (ret != 0) {
        /* ENODATA -- jack api does not guarantee that it won't ENODATA even if index_ < get_event_count.
           Setting size to 0 should prevent a sane programmer from accessing ev.buffer.
         */
        ev.size = 0;
    }
    return ev;
  }

  void popFront() {
    ++index_;
  }

};
