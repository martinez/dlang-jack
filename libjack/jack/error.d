
module jack.error;

class JackError: Exception {
  this(string msg) {
    super(msg);
  }
}
