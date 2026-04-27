package com.campuscircle.activities;

import android.os.Bundle;
import android.view.View;
import android.widget.*;
import androidx.appcompat.app.AppCompatActivity;
import com.campuscircle.R;
import com.campuscircle.api.ApiClient;
import com.campuscircle.models.Category;
import com.campuscircle.util.SessionManager;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import retrofit2.*;

public class PostItemActivity extends AppCompatActivity {

    private EditText etTitle, etPrice;
    private Spinner  spCategory, spType;
    private Button   btnSubmit;
    private ProgressBar progress;
    private List<Category> categories;

    @Override
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_post_item);

        etTitle    = findViewById(R.id.etTitle);
        etPrice    = findViewById(R.id.etPrice);
        spCategory = findViewById(R.id.spCategory);
        spType     = findViewById(R.id.spType);
        btnSubmit  = findViewById(R.id.btnSubmit);
        progress   = findViewById(R.id.progress);

        findViewById(R.id.btnBack).setOnClickListener(v -> finish());

        spType.setAdapter(new ArrayAdapter<>(this,
                android.R.layout.simple_spinner_dropdown_item,
                new String[]{"BUY", "RENT"}));

        loadCategories();
        btnSubmit.setOnClickListener(v -> submit());
    }

    private void loadCategories() {
        ApiClient.service().getCategories().enqueue(new Callback<List<Category>>() {
            @Override public void onResponse(Call<List<Category>> c, Response<List<Category>> r) {
                if (r.isSuccessful() && r.body() != null) {
                    categories = r.body();
                    spCategory.setAdapter(new ArrayAdapter<>(PostItemActivity.this,
                            android.R.layout.simple_spinner_dropdown_item, categories));
                }
            }
            @Override public void onFailure(Call<List<Category>> c, Throwable t) {
                Toast.makeText(PostItemActivity.this, "Can't load categories", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void submit() {
        if (categories == null || categories.isEmpty()) {
            Toast.makeText(this, "Categories loading...", Toast.LENGTH_SHORT).show();
            return;
        }
        String title = etTitle.getText().toString().trim();
        String priceStr = etPrice.getText().toString().trim();
        String type = (String) spType.getSelectedItem();
        Category cat = (Category) spCategory.getSelectedItem();

        if (title.isEmpty() || priceStr.isEmpty()) {
            Toast.makeText(this, "Fill all fields", Toast.LENGTH_SHORT).show();
            return;
        }
        double price = Double.parseDouble(priceStr);

        Map<String, Object> body = new HashMap<>();
        body.put("seller_id",   new SessionManager(this).getUserId());
        body.put("category_id", cat.category_id);
        body.put("title",       title);
        body.put("item_type",   type);
        if ("BUY".equals(type))  body.put("price", price);
        else                     body.put("rent_price_per_day", price);

        progress.setVisibility(View.VISIBLE);
        btnSubmit.setEnabled(false);

        ApiClient.service().createItem(body).enqueue(new Callback<Map<String, Integer>>() {
            @Override public void onResponse(Call<Map<String, Integer>> c, Response<Map<String, Integer>> r) {
                progress.setVisibility(View.GONE);
                btnSubmit.setEnabled(true);
                if (r.isSuccessful()) {
                    Toast.makeText(PostItemActivity.this, "Listing published!", Toast.LENGTH_LONG).show();
                    finish();
                } else {
                    Toast.makeText(PostItemActivity.this, "Could not publish", Toast.LENGTH_SHORT).show();
                }
            }
            @Override public void onFailure(Call<Map<String, Integer>> c, Throwable t) {
                progress.setVisibility(View.GONE);
                btnSubmit.setEnabled(true);
                Toast.makeText(PostItemActivity.this, "Network error", Toast.LENGTH_SHORT).show();
            }
        });
    }
}
