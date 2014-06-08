
module jack.impl.util;
import std.traits : isDelegate;
import std.conv : to;

template dgAllocCopy(T) if (isDelegate!T) {
  T *dgAllocCopy(T dg) {
    struct Tmp { T dg; }
    auto x = new Tmp;
    x.dg = dg;
    return &x.dg;
  }
}

string[] cStringListToD(const(char) **c_list)
{
  size_t len = 0;
  for (const(char) **p = c_list; *p; ++p)
    ++len;

  auto list = new string[len];
  foreach (i, ref string x; list)
    list[i] = to!string(c_list[i]);

  return list;
}
