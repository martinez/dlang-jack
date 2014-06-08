/*
  Based on gslist.c from glib-1.2.9 (LGPL).

  Adaption to JACK, Copyright (C) 2002 Kai Vehmanen.
    - replaced use of gtypes with normal ANSI C types
    - glib's memory allocation routines replaced with
      malloc/free calls

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU Lesser General Public License as published by
  the Free Software Foundation; either version 2.1 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

*/

module jack.c.jslist;
public import jack.c.systemdeps;
import core.stdc.stdlib;

extern(C)
{

alias JCompareFunc = int function(void* a, void* b);
struct JSList
{
    void *data;
    JSList *next;
};

// pragma(inline, true)
static
JSList*
jack_slist_alloc ()
{
    JSList *new_list;

    new_list = cast(JSList*)malloc(JSList.sizeof);
    if (new_list) {
        new_list.data = null;
        new_list.next = null;
    }

    return new_list;
}

// pragma(inline, true)
static
JSList*
jack_slist_prepend (JSList* list, void* data)
{
    JSList *new_list;

    new_list = cast(JSList*)malloc(JSList.sizeof);
    if (new_list) {
        new_list.data = data;
        new_list.next = list;
    }

    return new_list;
}

// pragma(inline, true)
static
JSList*
jack_slist_next (JSList *slist)
{
  return slist ? slist.next : null;
}

// pragma(inline, true)
static
JSList*
jack_slist_last (JSList *list)
{
    if (list) {
        while (list.next)
            list = list.next;
    }

    return list;
}

// pragma(inline, true)
static
JSList*
jack_slist_remove_link (JSList *list,
                        JSList *link)
{
    JSList *tmp;
    JSList *prev;

    prev = null;
    tmp = list;

    while (tmp) {
        if (tmp == link) {
            if (prev)
                prev.next = tmp.next;
            if (list == tmp)
                list = list.next;

            tmp.next = null;
            break;
        }

        prev = tmp;
        tmp = tmp.next;
    }

    return list;
}

// pragma(inline, true)
static
void
jack_slist_free (JSList *list)
{
    while (list) {
        JSList *next = list.next;
        free(list);
        list = next;
    }
}

// pragma(inline, true)
static
void
jack_slist_free_1 (JSList *list)
{
    if (list) {
        free(list);
    }
}

// pragma(inline, true)
static
JSList*
jack_slist_remove (JSList *list,
                   void *data)
{
    JSList *tmp;
    JSList *prev;

    prev = null;
    tmp = list;

    while (tmp) {
        if (tmp.data == data) {
            if (prev)
                prev.next = tmp.next;
            if (list == tmp)
                list = list.next;

            tmp.next = null;
            jack_slist_free (tmp);

            break;
        }

        prev = tmp;
        tmp = tmp.next;
    }

    return list;
}

// pragma(inline, true)
static
uint
jack_slist_length (JSList *list)
{
    uint length;

    length = 0;
    while (list) {
        length++;
        list = list.next;
    }

    return length;
}

// pragma(inline, true)
static
JSList*
jack_slist_find (JSList *list,
                 void *data)
{
    while (list) {
        if (list.data == data)
            break;
        list = list.next;
    }

    return list;
}

// pragma(inline, true)
static
JSList*
jack_slist_copy (JSList *list)
{
    JSList *new_list = null;

    if (list) {
        JSList *last;

        new_list = jack_slist_alloc ();
        new_list.data = list.data;
        last = new_list;
        list = list.next;
        while (list) {
            last.next = jack_slist_alloc ();
            last = last.next;
            last.data = list.data;
            list = list.next;
        }
    }

    return new_list;
}

// pragma(inline, true)
static
JSList*
jack_slist_append (JSList *list,
                   void *data)
{
    JSList *new_list;
    JSList *last;

    new_list = jack_slist_alloc ();
    new_list.data = data;

    if (list) {
        last = jack_slist_last (list);
        last.next = new_list;

        return list;
    } else
        return new_list;
}

// pragma(inline, true)
static
JSList*
jack_slist_sort_merge (JSList *l1,
                       JSList *l2,
                       JCompareFunc compare_func)
{
    JSList list;
    JSList *l;

    l = &list;

    while (l1 && l2) {
        if (compare_func(l1.data, l2.data) < 0) {
            l = l.next = l1;
            l1 = l1.next;
        } else {
            l = l.next = l2;
            l2 = l2.next;
        }
    }
    l.next = l1 ? l1 : l2;

    return list.next;
}

// pragma(inline, true)
static
JSList*
jack_slist_sort (JSList *list,
                 JCompareFunc compare_func)
{
    JSList *l1;
    JSList *l2;

    if (!list)
        return null;
    if (!list.next)
        return list;

    l1 = list;
    l2 = list.next;

    while ((l2 = l2.next) != null) {
        if ((l2 = l2.next) == null)
            break;
        l1 = l1.next;
    }
    l2 = l1.next;
    l1.next = null;

    return jack_slist_sort_merge (jack_slist_sort (list, compare_func),
                                  jack_slist_sort (l2, compare_func),
                                  compare_func);
}

}
