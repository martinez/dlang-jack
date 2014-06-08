
module jack.types;
public import jack.c.types;

alias JackThreadDelegate = void *delegate();
alias JackThreadInitDelegate = void delegate();
alias JackShutdownDelegate = void delegate();
alias JackInfoShutdownDelegate = void delegate(jack_status_t code, const(char)* reason);
alias JackProcessDelegate = int delegate(jack_nframes_t nframes);
alias JackFreewheelDelegate = void delegate(int starting);
alias JackBufferSizeDelegate = int delegate(jack_nframes_t nframes);
alias JackSampleRateDelegate = int delegate(jack_nframes_t nframes);
alias JackPortRegistrationDelegate = void delegate(jack_port_id_t port, int register);
alias JackPortConnectDelegate = void delegate(jack_port_id_t a, jack_port_id_t b, int connect);
alias JackPortRenameDelegate = int delegate(jack_port_id_t port, const(char)* old_name, const(char)* new_name);
alias JackGraphOrderDelegate = int delegate();
alias JackXRunDelegate = int delegate();
alias JackClientRegistrationDelegate = void delegate(const(char)* name, int register);
alias JackLatencyDelegate = void delegate(jack_latency_callback_mode_t mode);
