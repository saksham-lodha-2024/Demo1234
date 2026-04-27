package com.campuscircle.api;

import okhttp3.OkHttpClient;
import okhttp3.logging.HttpLoggingInterceptor;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

/**
 * Retrofit singleton.
 *
 *   BASE_URL — change this to whichever host runs your Node.js backend:
 *
 *   - Android Studio emulator  →  http://10.0.2.2:3000/
 *   - Physical phone on WiFi   →  http://<laptop-LAN-IP>:3000/
 *                                  (run `ipconfig` / `ifconfig` to find it)
 *   - Backend deployed anywhere →  http://yourhost.tld/
 */
public class ApiClient {

// /api/ hata do kyunki woh routes mein pehle se hoga
    public static final String BASE_URL = "http://10.174.20.197:3000/";
    private static Retrofit retrofit;

    public static Retrofit get() {
        if (retrofit == null) {
            HttpLoggingInterceptor log = new HttpLoggingInterceptor();
            log.setLevel(HttpLoggingInterceptor.Level.BODY);

            OkHttpClient http = new OkHttpClient.Builder()
                    .addInterceptor(log)
                    .build();

            retrofit = new Retrofit.Builder()
                    .baseUrl(BASE_URL)
                    .client(http)
                    .addConverterFactory(GsonConverterFactory.create())
                    .build();
        }
        return retrofit;
    }

    public static ApiService service() {
        return get().create(ApiService.class);
    }
}
