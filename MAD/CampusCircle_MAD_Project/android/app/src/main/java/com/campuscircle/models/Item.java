package com.campuscircle.models;

public class Item {
    public int     item_id;
    public String  title;
    public String  item_type;              // BUY / RENT
    public String  availability_status;
    public Double  price;
    public Double  rent_price_per_day;
    public String  price_display;          // "Rs.500.00" or "Rs.50.00 / day"
    public String  listed_on;
    public Integer category_id;
    public String  category_name;
    public Integer seller_id;
    public String  seller_name;
    public String  hostel_block;
}
