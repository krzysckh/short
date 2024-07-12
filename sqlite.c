#include <stdio.h>
#include <string.h>
#include <err.h>
#include <sqlite3.h>
#include <sys/types.h>

#include "ovm.h"

#define Eout(s) { warnx("sqlite.c: non-fatal runtime error: %s", s); return IFALSE; }

static char *last_err = NULL;

word
prim_custom(int op, word a, word b, word c)
{
  switch (op) {
  case 100: { /* filename → ptr */
    sqlite3 *db;
    if (sqlite3_open(cstr(a), &db) != SQLITE_OK)
      return IFALSE;
    return PTR(db);
  }
  case 101: /* ptr → #t ;; close sqlite context*/
    if (sqlite3_close(cptr(a)) == SQLITE_OK)
      return ITRUE;
    Eout(sqlite3_errmsg(cptr(a)));
  case 102: /* ptr sql → #t | #f ;; exec sqlite statement */
    if (sqlite3_exec(cptr(a), cstr(b), 0, 0, &last_err) != SQLITE_OK)
      Eout(last_err);
    return ITRUE;
  case 103: { /* ptr sql (data-to-bind) → array ;; exec select statement */
    sqlite3_stmt *res;
    int i = 1, v = sqlite3_prepare_v2(cptr(a), cstr(b), -1, &res, 0);
    word ret = INULL, l;

    if (v != SQLITE_OK)
      Eout(sqlite3_errmsg(cptr(a)));

    while (c != INULL) {
      if (is_type(car(c), TNUM))
        sqlite3_bind_int(res, i++, cnum(car(c)));
      else if (stringp(car(c)))
        sqlite3_bind_text(res, i++, cstr(car(c)), -1, SQLITE_STATIC);
      else
        Eout("Unsupported type for bind");

      c = cdr(c);
    }

    while (sqlite3_step(res) == SQLITE_ROW) {
      l = INULL;
      for (i = 0; i < sqlite3_column_count(res); ++i)
        l = cons(mkstring((uint8_t*)sqlite3_column_text(res, i)), l);
      ret = cons(l, ret);
    }

    if (sqlite3_finalize(res) != SQLITE_OK)
      Eout(sqlite3_errmsg(cptr(a)));

    return ret;
  }
  default:
    return IFALSE;
  }
}
