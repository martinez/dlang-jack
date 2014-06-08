/*
Copyright (C) 2004-2012 Grame

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation; either version 2.1 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

*/

module jack.c.systemdeps;
public import core.stdc.stdint;

version(Posix) {
  import core.sys.posix.sys.types : pthread_t;
  alias jack_native_thread_t = pthread_t;
}
version(Windows) {
  import core.sys.windows.windows : HANDLE;
  alias jack_native_thread_t = HANDLE;
}
