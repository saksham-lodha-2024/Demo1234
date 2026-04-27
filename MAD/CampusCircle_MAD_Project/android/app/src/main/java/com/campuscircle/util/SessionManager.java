package com.campuscircle.util;

import android.content.Context;
import android.content.SharedPreferences;
import com.campuscircle.models.User;

/**
 * Very thin wrapper over SharedPreferences.
 * We store the logged-in user_id + name so screens can get them on demand.
 */
public class SessionManager {
    private static final String PREFS = "campus_circle_prefs";
    private static final String K_USER_ID  = "user_id";
    private static final String K_NAME     = "name";
    private static final String K_EMAIL    = "email";
    private static final String K_HOSTEL   = "hostel_block";

    private final SharedPreferences sp;

    public SessionManager(Context ctx) {
        sp = ctx.getApplicationContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    public void save(User u) {
        sp.edit()
          .putInt   (K_USER_ID, u.user_id)
          .putString(K_NAME,    u.name)
          .putString(K_EMAIL,   u.email)
          .putString(K_HOSTEL,  u.hostel_block)
          .apply();
    }

    public void logout() { sp.edit().clear().apply(); }

    public boolean isLoggedIn() { return sp.getInt(K_USER_ID, 0) != 0; }
    public int     getUserId()  { return sp.getInt(K_USER_ID, 0); }
    public String  getName()    { return sp.getString(K_NAME,   ""); }
    public String  getEmail()   { return sp.getString(K_EMAIL,  ""); }
    public String  getHostel()  { return sp.getString(K_HOSTEL, ""); }
}
