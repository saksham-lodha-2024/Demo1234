package com.campuscircle.activities;

import android.os.Bundle;
import android.view.View;
import android.widget.*;
import androidx.appcompat.app.AppCompatActivity;
import com.campuscircle.R;
import com.campuscircle.api.ApiClient;
import com.campuscircle.models.ItemDetail;
import com.campuscircle.util.SessionManager;
import java.util.HashMap;
import java.util.Map;
import retrofit2.*;

public class ItemDetailActivity extends AppCompatActivity {

    private TextView tvTitle, tvPrice, tvCategory, tvStatus, tvSeller;
    private Button   btnRequest;
    private ProgressBar progress;
    private int itemId;
    private ItemDetail currentItem;

    @Override
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_item_detail);
        itemId = getIntent().getIntExtra("item_id", 0);

        tvTitle    = findViewById(R.id.tvTitle);
        tvPrice    = findViewById(R.id.tvPrice);
        tvCategory = findViewById(R.id.tvCategory);
        tvStatus   = findViewById(R.id.tvStatus);
        tvSeller   = findViewById(R.id.tvSeller);
        btnRequest = findViewById(R.id.btnRequest);
        progress   = findViewById(R.id.progress);

        findViewById(R.id.btnBack).setOnClickListener(v -> finish());
        btnRequest.setOnClickListener(v -> requestToBuy());

        load();
    }

    private void load() {
        progress.setVisibility(View.VISIBLE);
        ApiClient.service().getItem(itemId).enqueue(new Callback<ItemDetail>() {
            @Override public void onResponse(Call<ItemDetail> c, Response<ItemDetail> r) {
                progress.setVisibility(View.GONE);
                if (r.isSuccessful() && r.body() != null) {
                    currentItem = r.body();
                    render();
                }
            }
            @Override public void onFailure(Call<ItemDetail> c, Throwable t) {
                progress.setVisibility(View.GONE);
                Toast.makeText(ItemDetailActivity.this, "Network error", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void render() {
        tvTitle.setText(currentItem.title);
        if ("BUY".equalsIgnoreCase(currentItem.item_type))
            tvPrice.setText("Rs. " + currentItem.price);
        else
            tvPrice.setText("Rs. " + currentItem.rent_price_per_day + " / day");
        tvCategory.setText(currentItem.category_name + " · " + currentItem.item_type);
        tvStatus.setText(currentItem.availability_status != null
                ? currentItem.availability_status.toUpperCase() : "—");
        String seller = "Seller: " + currentItem.seller_name;
        if (currentItem.hostel_block != null) seller += " · " + currentItem.hostel_block;
        tvSeller.setText(seller);

        int myId = new SessionManager(this).getUserId();
        boolean canRequest = currentItem.seller_id != null
                && currentItem.seller_id != myId
                && "available".equalsIgnoreCase(currentItem.availability_status);
        btnRequest.setEnabled(canRequest);
        btnRequest.setText(canRequest ? "Request to Buy / Rent"
                : (currentItem.seller_id != null && currentItem.seller_id == myId
                        ? "This is your listing"
                        : "Not available"));
    }

    private void requestToBuy() {
        if (currentItem == null) return;
        Map<String, Object> body = new HashMap<>();
        body.put("item_id",  itemId);
        body.put("buyer_id", new SessionManager(this).getUserId());
        btnRequest.setEnabled(false);
        btnRequest.setText("Sending...");
        ApiClient.service().createTransaction(body).enqueue(new Callback<Map<String, Integer>>() {
            @Override public void onResponse(Call<Map<String, Integer>> c, Response<Map<String, Integer>> r) {
                if (r.isSuccessful()) {
                    Toast.makeText(ItemDetailActivity.this,
                            "Request sent to seller", Toast.LENGTH_LONG).show();
                    finish();
                } else {
                    btnRequest.setEnabled(true);
                    btnRequest.setText("Request to Buy / Rent");
                    Toast.makeText(ItemDetailActivity.this,
                            "Could not create request", Toast.LENGTH_SHORT).show();
                }
            }
            @Override public void onFailure(Call<Map<String, Integer>> c, Throwable t) {
                btnRequest.setEnabled(true);
                btnRequest.setText("Request to Buy / Rent");
                Toast.makeText(ItemDetailActivity.this, "Network error", Toast.LENGTH_SHORT).show();
            }
        });
    }
}
