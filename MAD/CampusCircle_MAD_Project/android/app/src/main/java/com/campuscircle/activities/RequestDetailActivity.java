package com.campuscircle.activities;

import android.os.Bundle;
import android.view.View;
import android.widget.*;
import androidx.appcompat.app.AppCompatActivity;
import com.campuscircle.R;
import com.campuscircle.api.ApiClient;
import com.campuscircle.models.Transaction;
import java.util.HashMap;
import java.util.Map;
import retrofit2.*;

/** Seller side: approve / reject a buyer's request. */
public class RequestDetailActivity extends AppCompatActivity {

    private TextView tvItem, tvBuyer, tvAmount, tvStatus;
    private Button   btnApprove, btnReject, btnBack;
    private ProgressBar progress;
    private int txnId;

    @Override
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_request_detail);
        txnId = getIntent().getIntExtra("transaction_id", 0);

        tvItem     = findViewById(R.id.tvItem);
        tvBuyer    = findViewById(R.id.tvBuyer);
        tvAmount   = findViewById(R.id.tvAmount);
        tvStatus   = findViewById(R.id.tvStatus);
        btnApprove = findViewById(R.id.btnApprove);
        btnReject  = findViewById(R.id.btnReject);
        btnBack    = findViewById(R.id.btnBack);
        progress   = findViewById(R.id.progress);

        btnBack.setOnClickListener(v -> finish());
        btnApprove.setOnClickListener(v -> updateStatus("approved"));
        btnReject .setOnClickListener(v -> updateStatus("rejected"));

        load();
    }

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
        String title = t.item_title != null ? t.item_title : t.title;
        tvItem.setText(title != null ? title : "Item #" + t.item_id);
        tvBuyer.setText("Buyer: " + (t.buyer_name != null ? t.buyer_name : "—"));
        tvAmount.setText("Amount: Rs. " + t.total_amount);
        tvStatus.setText("Status: " + t.status.toUpperCase());
        boolean canDecide = "requested".equals(t.status);
        btnApprove.setEnabled(canDecide);
        btnReject .setEnabled(canDecide);
    }

    private void updateStatus(String status) {
        Map<String, String> body = new HashMap<>();
        body.put("status", status);
        btnApprove.setEnabled(false);
        btnReject.setEnabled(false);
        ApiClient.service().updateTransactionStatus(txnId, body).enqueue(new Callback<Map<String, Object>>() {
            @Override public void onResponse(Call<Map<String, Object>> c, Response<Map<String, Object>> r) {
                Toast.makeText(RequestDetailActivity.this,
                        "Status → " + status.toUpperCase(), Toast.LENGTH_SHORT).show();
                finish();
            }
            // This is a comment
            @Override public void onFailure(Call<Map<String, Object>> c, Throwable t) {
                btnApprove.setEnabled(true);
                btnReject.setEnabled(true);
                Toast.makeText(RequestDetailActivity.this, "Network error", Toast.LENGTH_SHORT).show();
            }
        });
    }
}
