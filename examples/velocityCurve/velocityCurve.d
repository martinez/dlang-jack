
/**
 * A MIDI processor for Jack.
 * It alters the velocity of note messages according to a given curve function.
 */

module velocityCurve;
import jack.client;
import jack.midiport;
import std.stdio;
import std.math;
import core.stdc.string;

/// the curve function [0,1]->[0,1] is defined as
/// 1-((exp(s*(1-x))-1)/(exp(s)-1))
/// with the constant slope factor s=4
double curve(double x) {
  enum curve_s = 4.0;
  enum exp_curve_s = /*exp(curve_s)*/ 54.598150033144236;
  return 1.0 - (fastexp(curve_s * (1.0 - x)) - 1.0) / (exp_curve_s - 1.0);
}

void main()
{
  JackClient client = new JackClient;
  client.open("velocityCurve", JackOptions.JackNoStartServer, null);
  scope(exit) client.close();

  writeln("New jack_client with name: " ~ client.get_name());

  JackPort midi_in = client.register_port("In", JACK_DEFAULT_MIDI_TYPE, JackPortFlags.JackPortIsInput, 0);
  JackPort midi_out = client.register_port("Out", JACK_DEFAULT_MIDI_TYPE, JackPortFlags.JackPortIsOutput, 0);

  client.process_callback = delegate int(jack_nframes_t nframes) {
    JackMidiPortBuffer inbuf = midi_in.get_midi_buffer(nframes);
    JackMidiPortBuffer outbuf = midi_out.get_midi_buffer(nframes);

    outbuf.clear();

    foreach (JackMidiEvent event; inbuf.iter_events()) {

      if (event.buffer[0] & 0x80 || event.buffer[0] & 0x90) {
        double vel = event.buffer[2] / 127.0;
        double newvel = curve(vel);
        if (newvel < 0.0) newvel = 0.0;
        else if (newvel > 1.0) newvel = 1.0;
        event.buffer[2] = cast(ubyte)lrint(newvel * 127.0);
      }

      outbuf.write_event(event.time, event.buffer, event.size);
    }

    return 0;
  };

  client.activate();

  writeln("Press a key to stop.");
  stdin.readln();
}

/// fast approximate exp function
double fastexp(double x) {
  union U {
    double d;
    struct {
      version(BigEndian) { int32_t i, j; }
      version(LittleEndian) { int32_t j, i; }
    };
  }
  U u;
  u.d = 0.0;
  const double exp_a = 1048756.0 / LN2;
  const double exp_c = 60801.0;
  u.i = cast(int32_t)lrint(exp_a * x + (1072693248.0 - exp_c));
  return u.d;
};
