package com.campuscircle.activities;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.*;
import androidx.appcompat.app.AppCompatActivity;
import com.campuscircle.MainActivity;
import com.campuscircle.R;
import com.campuscircle.api.ApiClient;
import com.campuscircle.models.AuthResponse;
import com.campuscircle.util.SessionManager;

import java.util.HashMap;
import java.util.Map;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class LoginActivity extends AppCompatActivity {

    private EditText etEmail, etPassword;
    private Button   btnLogin;
    private TextView tvSignup;
    private ProgressBar progress;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_login);

        etEmail    = findViewById(R.id.etEmail);
        etPassword = findViewById(R.id.etPassword);
        btnLogin   = findViewById(R.id.btnLogin);
        tvSignup   = findViewById(R.id.tvSignup);
        progress   = findViewById(R.id.progress);

        btnLogin.setOnClickListener(v -> doLogin());
        tvSignup.setOnClickListener(v ->
                startActivity(new Intent(this, SignupActivity.class)));
    }

    private void doLogin() {
        String email = etEmail.getText().toString().trim();
        String pw    = etPassword.getText().toString();
        if (email.isEmpty() || pw.isEmpty()) {
            Toast.makeText(this, "Enter email and password", Toast.LENGTH_SHORT).show();
            return;
        }
        Map<String, String> body = new HashMap<>();
        body.put("email", email);
        body.put("password", pw);

        progress.setVisibility(View.VISIBLE);
        btnLogin.setEnabled(false);

        ApiClient.service().login(body).enqueue(new Callback<AuthResponse>() {
            @Override public void onResponse(Call<AuthResponse> c, Response<AuthResponse> r) {
                progress.setVisibility(View.GONE);
                btnLogin.setEnabled(true);
                if (r.isSuccessful() && r.body() != null && r.body().user != null) {
                    new SessionManager(LoginActivity.this).save(r.body().user);
                    startActivity(new Intent(LoginActivity.this, MainActivity.class));
                    finish();
                } else {
                    Toast.makeText(LoginActivity.this,
                            "Invalid email or password", Toast.LENGTH_SHORT).show();
                }
            }
            @Override public void onFailure(Call<AuthResponse> c, Throwable t) {
                progress.setVisibility(View.GONE);
                btnLogin.setEnabled(true);
                Toast.makeText(LoginActivity.this,
                        "Network error: " + t.getMessage(), Toast.LENGTH_LONG).show();
            }
        });
    }
}
