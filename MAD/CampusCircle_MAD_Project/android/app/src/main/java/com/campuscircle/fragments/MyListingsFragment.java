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
import com.campuscircle.activities.ItemDetailActivity;
import com.campuscircle.adapters.ItemAdapter;
import com.campuscircle.api.ApiClient;
import com.campuscircle.models.Item;
import com.campuscircle.util.SessionManager;
import java.util.ArrayList;
import java.util.List;
import retrofit2.*;

public class MyListingsFragment extends Fragment {
    private RecyclerView recycler;
    private ItemAdapter  adapter;
    private TextView     tvEmpty;

    @Nullable @Override
    public View onCreateView(@NonNull LayoutInflater inf, @Nullable ViewGroup c, @Nullable Bundle b) {
        return inf.inflate(R.layout.fragment_list, c, false);
    }

    @Override public void onViewCreated(@NonNull View v, @Nullable Bundle b) {
        recycler = v.findViewById(R.id.recycler);
        tvEmpty  = v.findViewById(R.id.tvEmpty);
        ((TextView) v.findViewById(R.id.tvTitle)).setText("My Listings");

        recycler.setLayoutManager(new LinearLayoutManager(getContext()));
        adapter = new ItemAdapter(new ArrayList<>(), item -> {
            Intent i = new Intent(getContext(), ItemDetailActivity.class);
            i.putExtra("item_id", item.item_id);
            startActivity(i);
        });
        recycler.setAdapter(adapter);
    }

    @Override public void onResume() {
        super.onResume();
        int uid = new SessionManager(getContext()).getUserId();
        ApiClient.service().getSellerItems(uid).enqueue(new Callback<List<Item>>() {
            @Override public void onResponse(Call<List<Item>> c, Response<List<Item>> r) {
                if (r.isSuccessful() && r.body() != null) {
                    adapter.setItems(r.body());
                    tvEmpty.setVisibility(r.body().isEmpty() ? View.VISIBLE : View.GONE);
                    tvEmpty.setText("No active listings yet.\nTap Home → Sell Item to post one.");
                }
            }
            @Override public void onFailure(Call<List<Item>> c, Throwable t) {
                tvEmpty.setVisibility(View.VISIBLE);
                tvEmpty.setText("Can't reach server.");
            }
        });
    }
}
