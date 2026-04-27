package com.campuscircle.fragments;

import android.content.Intent;
import android.os.Bundle;
import android.view.*;
import android.widget.*;
import androidx.annotation.*;
import androidx.fragment.app.Fragment;
import com.campuscircle.R;
import com.campuscircle.activities.LoginActivity;
import com.campuscircle.api.ApiClient;
import com.campuscircle.models.UserProfile;
import com.campuscircle.util.SessionManager;
import retrofit2.*;

public class ProfileFragment extends Fragment {

    private TextView tvName, tvEmail, tvHostel, tvRating, tvReviews, tvEarnings,
                     tvListings, tvActive, tvSold, tvCompleted;
    private Button   btnLogout;

    @Nullable @Override
    public View onCreateView(@NonNull LayoutInflater inf, @Nullable ViewGroup c, @Nullable Bundle b) {
        return inf.inflate(R.layout.fragment_profile, c, false);
    }

    @Override public void onViewCreated(@NonNull View v, @Nullable Bundle b) {
        tvName      = v.findViewById(R.id.tvName);
        tvEmail     = v.findViewById(R.id.tvEmail);
        tvHostel    = v.findViewById(R.id.tvHostel);
        tvRating    = v.findViewById(R.id.tvRating);
        tvReviews   = v.findViewById(R.id.tvReviews);
        tvEarnings  = v.findViewById(R.id.tvEarnings);
        tvListings  = v.findViewById(R.id.tvListings);
        tvActive    = v.findViewById(R.id.tvActive);
        tvSold      = v.findViewById(R.id.tvSold);
        tvCompleted = v.findViewById(R.id.tvCompleted);
        btnLogout   = v.findViewById(R.id.btnLogout);

        btnLogout.setOnClickListener(x -> {
            new SessionManager(getContext()).logout();
            Intent i = new Intent(getContext(), LoginActivity.class);
            i.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
            startActivity(i);
        });
    }

    @Override public void onResume() {
        super.onResume();
        int uid = new SessionManager(getContext()).getUserId();
        ApiClient.service().getUserProfile(uid).enqueue(new Callback<UserProfile>() {
            @Override public void onResponse(Call<UserProfile> c, Response<UserProfile> r) {
                if (r.isSuccessful() && r.body() != null) render(r.body());
            }
            @Override public void onFailure(Call<UserProfile> c, Throwable t) { }
        });
    }

    private void render(UserProfile p) {
        tvName.setText(p.name != null ? p.name : "—");
        tvEmail.setText(p.email != null ? p.email : "");
        tvHostel.setText(p.hostel_block != null ? "Hostel " + p.hostel_block : "");
        tvRating.setText(String.valueOf(p.avg_rating != null ? p.avg_rating : 0.0));
        tvReviews.setText("Reviews: " + (p.review_count != null ? p.review_count : 0));
        tvEarnings.setText("Rs. " + (p.total_earnings != null ? p.total_earnings : 0));
        if (p.dashboard != null) {
            tvListings.setText(String.valueOf(p.dashboard.total_listings));
            tvActive.setText(String.valueOf(p.dashboard.active_listings));
            tvSold.setText(String.valueOf(p.dashboard.items_sold != null ? p.dashboard.items_sold : 0));
            tvCompleted.setText(String.valueOf(p.dashboard.completed_transactions));
        }
    }
}
