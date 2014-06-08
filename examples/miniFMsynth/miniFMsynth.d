
/**
 * A simple FM synthesizer with Jack.
 * It is a port of the miniFMsynth example from ALSA.
 */

module miniFMsynth;
import jack.client;
import jack.midiport;
import std.stdio;
import std.math;
import core.stdc.string;

void main()
{
  JackClient client = new JackClient;
  client.open("miniFMsynth", JackOptions.JackNoStartServer, null);
  scope(exit) client.close();

  writeln("New jack_client with name: " ~ client.get_name());

  JackPort midi = client.register_port("In", JACK_DEFAULT_MIDI_TYPE, JackPortFlags.JackPortIsInput, 0);
  JackPort out1 = client.register_port("Out1", JACK_DEFAULT_AUDIO_TYPE, JackPortFlags.JackPortIsOutput, 0);
  JackPort out2 = client.register_port("Out2", JACK_DEFAULT_AUDIO_TYPE, JackPortFlags.JackPortIsOutput, 0);

  auto fm = new SynthFM;
  fm.srate = client.get_sample_rate();
  fm.buf = new short[client.get_buffer_size()];

  fm.modulation = 7.8;
  fm.harmonic = 3;
  fm.subharmonic = 5;
  fm.transpose = 24;
  fm.attack = 0.01;
  fm.decay = 0.8;
  fm.sustain = 0.0;
  fm.release = 0.1;
  fm.pitch = 0.0;

  client.process_callback = delegate int(jack_nframes_t nframes) {
    JackMidiPortBuffer midibuf = midi.get_midi_buffer(nframes);
    foreach (JackMidiEvent event; midibuf.iter_events()) {
      if (event.size == 3) {
        if (event.buffer[0] == 0x80 ||
            event.buffer[0] == 0x90 && event.buffer[2] == 0)
          fm.noteoff(event.buffer[1], event.buffer[2]);
        else if (event.buffer[0] == 0x90)
          fm.noteon(event.buffer[1], event.buffer[2]);
      }
    }

    float *buf1 = out1.get_audio_buffer(nframes);
    float *buf2 = out2.get_audio_buffer(nframes);

    fm.compute(nframes);

    for (jack_nframes_t i = 0; i < nframes; ++i) {
      buf1[i] = cast(double)fm.buf[i] / short.max;
    }
    buf2[0..nframes] = buf1[0..nframes];

    return 0;
  };

  client.activate();

  writeln("Press a key to stop.");
  stdin.readln();
}

class SynthFM
{
  double srate;

  enum POLY = 10;
  enum GAIN = 5000.0;

  short[] buf;
  double pitch, modulation, attack, decay, sustain, release;
  double[POLY] phi, phi_mod, velocity, env_time, env_level;
  int harmonic, subharmonic, transpose, rate;
  int[POLY] note, gate, note_active;

  this() {
    for (uint i = 0; i < POLY; ++i) {
      phi[i] = 0.0;
      phi_mod[i] = 0.0;
      velocity[i] = 0.0;
      env_time[i] = 0.0;
      env_level[i] = 0.0;
    }
  }

  void noteon(int note, int vel)
  {
    for (uint l1 = 0; l1 < POLY; l1++) {
      if (! note_active[l1]) {
        this.note[l1] = note;
        velocity[l1] = vel / 127.0;
        env_time[l1] = 0;
        gate[l1] = 1;
        note_active[l1] = 1;
        break;
      }
    }
  }

  void noteoff(int note, int vel)
  {
    for (uint l1 = 0; l1 < POLY; l1++) {
      if (gate[l1] && note_active[l1] && (this.note[l1] == note)) {
        env_time[l1] = 0;
        gate[l1] = 0;
      }
    }
  }

  static double envelope(int *note_active, int gate, double *env_level, double t, double attack, double decay, double sustain, double release)
  {
    if (gate)  {
      if (t > attack + decay) return(*env_level = sustain);
      if (t > attack) return(*env_level = 1.0 - (1.0 - sustain) * (t - attack) / decay);
      return(*env_level = t / attack);
    } else {
      if (t > release) {
        if (note_active) *note_active = 0;
        return(*env_level = 0);
      }
      return(*env_level * (1.0 - t / release));
    }
  }

  void compute(uint nframes)
  {
    short *buf = this.buf.ptr;

    memset(buf, 0, nframes * float.sizeof);
    for (int l2 = 0; l2 < POLY; l2++) {
      if (note_active[l2]) {
        double f1 = 8.176 * exp(cast(double)(transpose+note[l2]-2)*log(2.0)/12.0);
        double f2 = 8.176 * exp(cast(double)(transpose+note[l2])*log(2.0)/12.0);
        double f3 = 8.176 * exp(cast(double)(transpose+note[l2]+2)*log(2.0)/12.0);
        double freq_note = (pitch > 0) ? f2 + (f3-f2)*pitch : f2 + (f2-f1)*pitch;
        double dphi = PI * freq_note / (srate / 2.0);
        double dphi_mod = dphi * cast(double)harmonic / cast(double)subharmonic;
        for (int l1 = 0; l1 < nframes; l1++) {
          phi[l2] += dphi;
          phi_mod[l2] += dphi_mod;
          if (phi[l2] > 2.0 * PI) phi[l2] -= 2.0 * PI;
          if (phi_mod[l2] > 2.0 * PI) phi_mod[l2] -= 2.0 * PI;
          double env = envelope(&note_active[l2], gate[l2], &env_level[l2], env_time[l2], attack, decay, sustain, release);
          double sound = GAIN * env
            * velocity[l2] * sin(phi[l2] + modulation * sin(phi_mod[l2]));
          env_time[l2] += 1.0 / srate;
          buf[l1] += sound;
        }
      }
    }
  }
}
