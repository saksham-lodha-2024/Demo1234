package com.campuscircle.activities;

import android.os.Bundle;
import android.view.View;
import android.widget.*;
import androidx.appcompat.app.AppCompatActivity;
import com.campuscircle.R;
import com.campuscircle.api.ApiClient;
import com.campuscircle.util.SessionManager;
import java.util.HashMap;
import java.util.Map;
import retrofit2.*;

public class ReviewActivity extends AppCompatActivity {

    private RatingBar rbRating;
    private EditText  etComment;
    private Button    btnSubmit, btnBack;
    private ProgressBar progress;
    private int txnId;

    @Override
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_review);
        txnId = getIntent().getIntExtra("transaction_id", 0);

        rbRating  = findViewById(R.id.rbRating);
        etComment = findViewById(R.id.etComment);
        btnSubmit = findViewById(R.id.btnSubmit);
        btnBack   = findViewById(R.id.btnBack);
        progress  = findViewById(R.id.progress);

        btnBack.setOnClickListener(v -> finish());
        btnSubmit.setOnClickListener(v -> submit());
    }

    private void submit() {
        int rating = Math.round(rbRating.getRating());
        if (rating < 1) {
            Toast.makeText(this, "Give a rating first", Toast.LENGTH_SHORT).show();
            return;
        }
        Map<String, Object> body = new HashMap<>();
        body.put("transaction_id", txnId);
        body.put("reviewer_id",    new SessionManager(this).getUserId());
        body.put("rating",         rating);
        body.put("comment",        etComment.getText().toString());

        progress.setVisibility(View.VISIBLE);
        btnSubmit.setEnabled(false);

        ApiClient.service().submitReview(body).enqueue(new Callback<Map<String, Integer>>() {
            @Override public void onResponse(Call<Map<String, Integer>> c, Response<Map<String, Integer>> r) {
                progress.setVisibility(View.GONE);
                btnSubmit.setEnabled(true);
                if (r.isSuccessful()) {
                    Toast.makeText(ReviewActivity.this, "Review submitted", Toast.LENGTH_SHORT).show();
                    finish();
                } else {
                    Toast.makeText(ReviewActivity.this, "Could not submit", Toast.LENGTH_SHORT).show();
                }
            }
            @Override public void onFailure(Call<Map<String, Integer>> c, Throwable t) {
                progress.setVisibility(View.GONE);
                btnSubmit.setEnabled(true);
                Toast.makeText(ReviewActivity.this, "Network error", Toast.LENGTH_SHORT).show();
            }
        });
    }
}
