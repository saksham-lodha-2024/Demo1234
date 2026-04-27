package com.campuscircle.adapters;

import android.view.*;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.campuscircle.R;
import com.campuscircle.models.Item;
import java.util.List;

/**
 * ViewHolder-pattern RecyclerView adapter for items.
 * Matches Lecture 7 (RecyclerView) expectations from the syllabus.
 */
public class ItemAdapter extends RecyclerView.Adapter<ItemAdapter.VH> {

    public interface OnItemClick { void onClick(Item item); }

    private List<Item>   items;
    private final OnItemClick cb;

    public ItemAdapter(List<Item> items, OnItemClick cb) {
        this.items = items;
        this.cb    = cb;
    }

    public void setItems(List<Item> newItems) {
        this.items = newItems;
        notifyDataSetChanged();
    }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.row_item, parent, false);
        return new VH(v);
    }

    @Override public void onBindViewHolder(@NonNull VH h, int pos) {
        Item it = items.get(pos);
        h.title.setText(it.title);
        h.price.setText(it.price_display != null ? it.price_display : "Rs.—");
        h.category.setText(it.category_name + "  ·  " + it.item_type);
        h.seller.setText("by " + it.seller_name + (it.hostel_block != null ? " · " + it.hostel_block : ""));
        h.itemView.setOnClickListener(v -> cb.onClick(it));
    }

    @Override public int getItemCount() { return items == null ? 0 : items.size(); }

    static class VH extends RecyclerView.ViewHolder {
        TextView title, price, category, seller;
        VH(View v) {
            super(v);
            title    = v.findViewById(R.id.tvTitle);
            price    = v.findViewById(R.id.tvPrice);
            category = v.findViewById(R.id.tvCategory);
            seller   = v.findViewById(R.id.tvSeller);
        }
    }
}
