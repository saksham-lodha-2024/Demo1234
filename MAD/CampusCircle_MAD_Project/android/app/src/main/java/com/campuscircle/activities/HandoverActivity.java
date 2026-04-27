package com.campuscircle.activities;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.*;
import androidx.appcompat.app.AppCompatActivity;
import com.campuscircle.R;
import com.campuscircle.api.ApiClient;
import com.campuscircle.models.Transaction;
import retrofit2.*;

/** Buyer side after approval — "Mark Completed" → sp_complete_transaction, then go to ReviewActivity. */
public class HandoverActivity extends AppCompatActivity {

    private TextView tvItem, tvSeller, tvStatus, tvAmount;
    private Button   btnComplete, btnReview, btnBack;
    private ProgressBar progress;
    private int txnId;
    private Transaction currentTxn;

    @Override
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_handover);
        txnId = getIntent().getIntExtra("transaction_id", 0);

        tvItem      = findViewById(R.id.tvItem);
        tvSeller    = findViewById(R.id.tvSeller);
        tvStatus    = findViewById(R.id.tvStatus);
        tvAmount    = findViewById(R.id.tvAmount);
        btnComplete = findViewById(R.id.btnComplete);
        btnReview   = findViewById(R.id.btnReview);
        btnBack     = findViewById(R.id.btnBack);
        progress    = findViewById(R.id.progress);

        btnBack.setOnClickListener(v -> finish());
        btnComplete.setOnClickListener(v -> markCompleted());
        btnReview.setOnClickListener(v -> {
            Intent i = new Intent(this, ReviewActivity.class);
            i.putExtra("transaction_id", txnId);
            startActivity(i);
            finish();
        });
    }

    @Override protected void onResume() { super.onResume(); load(); }

    private void load() {
        progress.setVisibility(View.VISIBLE);
        ApiClient.service().getTransaction(txnId).enqueue(new Callback<Transaction>() {
            @Override public void onResponse(Call<Transaction> c, Response<Transaction> r) {
                progress.setVisibility(View.GONE);
                if (r.isSuccessful() && r.body() != null) render(r.body());
            }
            @Override public void onFailure(Call<Transaction> c, Throwable t) {
                progress.setVisibility(View.GONE);
            }
        });
    }

    private void render(Transaction t) {
        currentTxn = t;
        String title = t.item_title != null ? t.item_title : t.title;
        tvItem.setText(title != null ? title : "Item #" + t.item_id);
        tvSeller.setText("Seller: " + (t.seller_name != null ? t.seller_name : "—"));
        tvAmount.setText("Amount: Rs. " + t.total_amount);
        tvStatus.setText("Status: " + t.status.toUpperCase());

        btnComplete.setVisibility("approved".equals(t.status) || "active".equals(t.status) ? View.VISIBLE : View.GONE);
        btnReview  .setVisibility("completed".equals(t.status) ? View.VISIBLE : View.GONE);
    }

    private void markCompleted() {
        btnComplete.setEnabled(false);
        ApiClient.service().completeTransaction(txnId).enqueue(new Callback<java.util.Map<String, Object>>() {
            @Override public void onResponse(Call<java.util.Map<String, Object>> c,
                                             Response<java.util.Map<String, Object>> r) {
                btnComplete.setEnabled(true);
                if (r.isSuccessful()) {
                    Toast.makeText(HandoverActivity.this, "Transaction completed", Toast.LENGTH_SHORT).show();
                    load();
                }
            }
            @Override public void onFailure(Call<java.util.Map<String, Object>> c, Throwable t) {
                btnComplete.setEnabled(true);
                Toast.makeText(HandoverActivity.this, "Network error", Toast.LENGTH_SHORT).show();
            }
        });
    }
}
