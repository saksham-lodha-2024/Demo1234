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

public class SignupActivity extends AppCompatActivity {

    private EditText etName, etEmail, etPassword, etPhone, etHostel;
    private Button   btnSignup;
    private TextView tvLogin;
    private ProgressBar progress;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_signup);

        etName     = findViewById(R.id.etName);
        etEmail    = findViewById(R.id.etEmail);
        etPassword = findViewById(R.id.etPassword);
        etPhone    = findViewById(R.id.etPhone);
        etHostel   = findViewById(R.id.etHostel);
        btnSignup  = findViewById(R.id.btnSignup);
        tvLogin    = findViewById(R.id.tvLogin);
        progress   = findViewById(R.id.progress);

        btnSignup.setOnClickListener(v -> doSignup());
        tvLogin.setOnClickListener(v -> finish());
    }

    private void doSignup() {
        String name     = etName.getText().toString().trim();
        String email    = etEmail.getText().toString().trim();
        String password = etPassword.getText().toString();
        String phone    = etPhone.getText().toString().trim();
        String hostel   = etHostel.getText().toString().trim();

        if (name.isEmpty() || email.isEmpty() || password.isEmpty()) {
            Toast.makeText(this, "Please fill name, email, password", Toast.LENGTH_SHORT).show();
            return;
        }

        Map<String, Object> body = new HashMap<>();
        body.put("name", name);
        body.put("email", email);
        body.put("password", password);
        body.put("phone_number", phone);
        body.put("hostel_block", hostel);

        progress.setVisibility(View.VISIBLE);
        btnSignup.setEnabled(false);

        ApiClient.service().signup(body).enqueue(new Callback<AuthResponse>() {
            @Override public void onResponse(Call<AuthResponse> c, Response<AuthResponse> r) {
                progress.setVisibility(View.GONE);
                btnSignup.setEnabled(true);
                if (r.isSuccessful() && r.body() != null && r.body().user != null) {
                    new SessionManager(SignupActivity.this).save(r.body().user);
                    startActivity(new Intent(SignupActivity.this, MainActivity.class));
                    finishAffinity();
                } else {
                    Toast.makeText(SignupActivity.this,
                            "Signup failed — try a different email", Toast.LENGTH_SHORT).show();
                }
            }
            @Override public void onFailure(Call<AuthResponse> c, Throwable t) {
                progress.setVisibility(View.GONE);
                btnSignup.setEnabled(true);
                Toast.makeText(SignupActivity.this,
                        "Network error: " + t.getMessage(), Toast.LENGTH_LONG).show();
            }
        });
    }
}
