package com.campuscircle.fragments;

import android.content.Intent;
import android.os.Bundle;
import android.view.*;
import android.widget.*;
import androidx.annotation.*;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.campuscircle.R;
import com.campuscircle.activities.HandoverActivity;
import com.campuscircle.activities.RequestDetailActivity;
import com.campuscircle.adapters.TransactionAdapter;
import com.campuscircle.api.ApiClient;
import com.campuscircle.models.Transaction;
import com.campuscircle.util.SessionManager;
import java.util.ArrayList;
import java.util.List;
import retrofit2.*;

/**
 * Shows two tabs (as simple buttons): "As Buyer" | "As Seller".
 * Clicking a row opens RequestDetailActivity (seller side) or HandoverActivity (buyer side).
 */
public class RequestsFragment extends Fragment {

    private RecyclerView recycler;
    private TransactionAdapter adapter;
    private Button btnBuyer, btnSeller;
    private TextView tvEmpty;
    private boolean sellerMode = false;

    @Nullable @Override
    public View onCreateView(@NonNull LayoutInflater inf, @Nullable ViewGroup c, @Nullable Bundle b) {
        return inf.inflate(R.layout.fragment_requests, c, false);
    }

    @Override public void onViewCreated(@NonNull View v, @Nullable Bundle b) {
        recycler  = v.findViewById(R.id.recycler);
        tvEmpty   = v.findViewById(R.id.tvEmpty);
        btnBuyer  = v.findViewById(R.id.btnBuyer);
        btnSeller = v.findViewById(R.id.btnSeller);

        recycler.setLayoutManager(new LinearLayoutManager(getContext()));
        adapter = new TransactionAdapter(new ArrayList<>(), sellerMode, t -> {
            Intent i;
            if (sellerMode) {
                i = new Intent(getContext(), RequestDetailActivity.class);
            } else {
                i = new Intent(getContext(), HandoverActivity.class);
            }
            i.putExtra("transaction_id", t.transaction_id);
            startActivity(i);
        });
        recycler.setAdapter(adapter);

        btnBuyer.setOnClickListener(x  -> { sellerMode = false; refresh(); });
        btnSeller.setOnClickListener(x -> { sellerMode = true;  refresh(); });
    }

    @Override public void onResume() { super.onResume(); refresh(); }

    private void refresh() {
        btnBuyer.setBackgroundTintList(
                getResources().getColorStateList(sellerMode ? R.color.cc_muted : R.color.cc_primary, null));
        btnSeller.setBackgroundTintList(
                getResources().getColorStateList(sellerMode ? R.color.cc_primary : R.color.cc_muted, null));

        int uid = new SessionManager(getContext()).getUserId();
        Call<List<Transaction>> call = sellerMode
                ? ApiClient.service().getSellerTransactions(uid)
                : ApiClient.service().getBuyerTransactions(uid);

        adapter = new TransactionAdapter(new ArrayList<>(), sellerMode, t -> {
            Intent i;
            if (sellerMode) i = new Intent(getContext(), RequestDetailActivity.class);
            else            i = new Intent(getContext(), HandoverActivity.class);
            i.putExtra("transaction_id", t.transaction_id);
            startActivity(i);
        });
        recycler.setAdapter(adapter);

        call.enqueue(new Callback<List<Transaction>>() {
            @Override public void onResponse(Call<List<Transaction>> c, Response<List<Transaction>> r) {
                if (r.isSuccessful() && r.body() != null) {
                    adapter.setItems(r.body());
                    tvEmpty.setVisibility(r.body().isEmpty() ? View.VISIBLE : View.GONE);
                    tvEmpty.setText(sellerMode ? "No buy requests yet." : "You haven't requested anything yet.");
                }
            }
            @Override public void onFailure(Call<List<Transaction>> c, Throwable t) {
                tvEmpty.setVisibility(View.VISIBLE);
                tvEmpty.setText("Can't reach server.");
            }
        });
    }
}
