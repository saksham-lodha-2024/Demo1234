package com.campuscircle.models;

public class Transaction {
    public int     transaction_id;
    public String  status;             // requested / approved / active / completed / cancelled / rejected
    public String  payment_status;
    public Double  total_amount;
    public String  transaction_type;
    public String  start_date;
    public String  end_date;
    public String  created_at;

    public int     item_id;
    public String  title;              // sometimes "item_title" from backend — handled in adapter
    public String  item_title;

    public Integer buyer_id;
    public String  buyer_name;
    public String  buyer_hostel;
    public Integer seller_id;
    public String  seller_name;
    public String  seller_hostel;
}
