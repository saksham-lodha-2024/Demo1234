package com.campuscircle.adapters;

import android.view.*;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.campuscircle.R;
import com.campuscircle.models.Transaction;
import java.util.List;

public class TransactionAdapter extends RecyclerView.Adapter<TransactionAdapter.VH> {

    public interface OnTxnClick { void onClick(Transaction txn); }

    private List<Transaction> items;
    private final OnTxnClick  cb;
    private final boolean     sellerMode;

    public TransactionAdapter(List<Transaction> items, boolean sellerMode, OnTxnClick cb) {
        this.items = items;
        this.cb    = cb;
        this.sellerMode = sellerMode;
    }

    public void setItems(List<Transaction> newItems) { this.items = newItems; notifyDataSetChanged(); }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.row_transaction, parent, false);
        return new VH(v);
    }

    @Override public void onBindViewHolder(@NonNull VH h, int pos) {
        Transaction t = items.get(pos);
        String title = t.item_title != null ? t.item_title : t.title;
        h.title.setText(title != null ? title : "Item #" + t.item_id);
        h.status.setText(t.status.toUpperCase());
        h.amount.setText("Rs. " + (t.total_amount != null ? t.total_amount : 0));
        String counterparty = sellerMode
                ? ("Buyer: " + (t.buyer_name != null ? t.buyer_name : "—"))
                : ("Seller: " + (t.seller_name != null ? t.seller_name : "—"));
        h.counterparty.setText(counterparty);
        h.itemView.setOnClickListener(v -> cb.onClick(t));
    }

    @Override public int getItemCount() { return items == null ? 0 : items.size(); }

    static class VH extends RecyclerView.ViewHolder {
        TextView title, status, amount, counterparty;
        VH(View v) {
            super(v);
            title        = v.findViewById(R.id.tvTitle);
            status       = v.findViewById(R.id.tvStatus);
            amount       = v.findViewById(R.id.tvAmount);
            counterparty = v.findViewById(R.id.tvCounterparty);
        }
    }
}
