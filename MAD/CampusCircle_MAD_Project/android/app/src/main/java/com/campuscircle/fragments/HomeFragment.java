package com.campuscircle.fragments;

import android.content.Intent;
import android.os.Bundle;
import android.view.*;
import android.widget.*;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.campuscircle.R;
import com.campuscircle.activities.ItemDetailActivity;
import com.campuscircle.activities.PostItemActivity;
import com.campuscircle.adapters.ItemAdapter;
import com.campuscircle.api.ApiClient;
import com.campuscircle.models.Item;
import java.util.ArrayList;
import java.util.List;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

/** Campus Market — scroll of all active listings from v_active_listings. */
public class HomeFragment extends Fragment {

    private RecyclerView recycler;
    private ItemAdapter  adapter;
    private ProgressBar  progress;
    private TextView     tvEmpty;
    private Button       btnPost;

    @Nullable @Override
    public View onCreateView(@NonNull LayoutInflater inf, @Nullable ViewGroup c, @Nullable Bundle b) {
        return inf.inflate(R.layout.fragment_home, c, false);
    }

    @Override public void onViewCreated(@NonNull View v, @Nullable Bundle b) {
        recycler = v.findViewById(R.id.recycler);
        progress = v.findViewById(R.id.progress);
        tvEmpty  = v.findViewById(R.id.tvEmpty);
        btnPost  = v.findViewById(R.id.btnPost);

        recycler.setLayoutManager(new LinearLayoutManager(getContext()));
        adapter = new ItemAdapter(new ArrayList<>(), item -> {
            Intent i = new Intent(getContext(), ItemDetailActivity.class);
            i.putExtra("item_id", item.item_id);
            startActivity(i);
        });
        recycler.setAdapter(adapter);

        btnPost.setOnClickListener(x ->
                startActivity(new Intent(getContext(), PostItemActivity.class)));
    }

    @Override public void onResume() {
        super.onResume();
        loadItems();
    }

    private void loadItems() {
        progress.setVisibility(View.VISIBLE);
        tvEmpty.setVisibility(View.GONE);

        ApiClient.service().getItems(null).enqueue(new Callback<List<Item>>() {
            @Override public void onResponse(Call<List<Item>> c, Response<List<Item>> r) {
                progress.setVisibility(View.GONE);
                if (r.isSuccessful() && r.body() != null) {
                    adapter.setItems(r.body());
                    tvEmpty.setVisibility(r.body().isEmpty() ? View.VISIBLE : View.GONE);
                }
            }
            @Override public void onFailure(Call<List<Item>> c, Throwable t) {
                progress.setVisibility(View.GONE);
                tvEmpty.setText("Can't reach server — start the backend.");
                tvEmpty.setVisibility(View.VISIBLE);
            }
        });
    }
}
